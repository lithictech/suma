# frozen_string_literal: true

require "rake/tasklib"
require "sequel"

require "suma/tasks"
require "suma/tasks/db"
require "suma/tasks/i18n"
require "suma/tasks/sidekiq"

class Suma::Tasks::Release < Rake::TaskLib
  PASSWORD = "suma1234"

  def initialize
    super
    desc "Run the release script against the current environment."
    task :release do
      Rake::Task["db:migrate"].invoke
      Rake::Task["i18n:import"].invoke
      Rake::Task["sidekiq:release"].invoke
    end

    namespace :release do
      desc "Prepare the current database dump for local development by " \
           "setting every user password to #{PASSWORD} and " \
           "undeleting the admin@lithic.tech user."
      task :prepare_prod_db_for_local do
        # Do NOT use load_app. We may have local migrations not applied to the dump,
        # and we'll error trying to load those models.
        require "suma/member"
        m = Suma::Member.new
        m.password = Suma::Tasks::Bootstrap::Meta::ADMIN_PASS
        Sequel.connect(Suma::Postgres::Model.uri) do |conn|
          conn[:members].update(
            password_digest: m.password_digest,
            stripe_customer_json: nil,
          )
          conn[:members].where(email: "admin@lithic.tech").update(
            phone: Suma::Tasks::Bootstrap::Meta::ADMIN_PHONE,
            soft_deleted_at: nil,
          )
        end
      end

      desc "Randomize all member passwords."
      task :randomize_passwords do
        Suma.load_app?
        Suma::Member.exclude(email: nil).each do |m|
          pw = SecureRandom.hex(24)
          m.update(password: pw)
          $stdout << "#{m.email}: #{pw}\n"
        end
      end

      desc "Given a PG dump at the given path, restore platform (non-member) data."
      task :restore_staging_db_from_dump, [:path] do |_, args|
        # This routine is pretty fun. Here's what we do:
        # - First, reset the DB to a clean state by dropping all tables,
        #   and then reloading schemas (not data) from the dump.
        # - We can safely load the app at this point since schemas are correct.
        # - Convert all the ON RESTRICT (or NO ACTION, same thing) FKs to CASCADE.
        # - Load in all data (we could do this before the CASCADE, but it's easier to split it up for dev purposes).
        # - Truncate some sensitive tables we want to remove entirely.
        # - Delete all members who are not admins. The DELETE will cascade and clean up all associated data.
        # - Remove some selective data, like now-unused addresses.
        anon = StagingAnonymizer.new(args.fetch(:path))
        require "suma/postgres"
        anon.drop_all_tables
        anon.run_pgrestore("--clean --if-exists --schema-only")

        Suma.load_app?
        anon.each_fk_constraint do |schema, tbl, con|
          anon.cascade_constraint(schema, tbl, con)
        end

        anon.run_pgrestore("--data-only --disable-triggers")
        anon.truncate_analytics

        anon.tables_to_truncate.each do |schema, tables|
          tables.each { |tbl| anon.truncate(schema, tbl) }
        end
        anon.delete_selective

        anon.each_fk_constraint do |schema, tbl, con|
          anon.restore_constraint(schema, tbl, con)
        end
      end
    end
  end

  class StagingAnonymizer
    def initialize(dump)
      @dump = dump
      @dburl = Suma::Postgres::Model.uri
      @db = Suma::Member.db
      @constraint_originals = {}
    end

    def drop_all_tables = self.class.drop_all_tables

    def self.drop_all_tables
      Suma::Postgres.drop_all_tables
    end

    def run_pgrestore(params) = self.class.run_pgrestore(%(--no-acl --no-owner #{params} -d "#{@dburl}" "#{@dump}"))

    def self.run_pgrestore(argstr)
      `pg_restore #{argstr}`
    end

    def _fetch_constraint_def(schema, table, constraint_name)
      result = @db.fetch(<<~SQL, schema.to_s, table.to_s, constraint_name.to_s).all
        SELECT pg_get_constraintdef(c.oid) AS def
        FROM pg_constraint c
        JOIN pg_class t ON t.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE n.nspname = ? AND t.relname = ? AND c.conname = ?
      SQL
      raise "Constraint not found: #{schema}.#{table}.#{constraint_name}" if result.empty?
      result[0][:def]
    end

    def cascade_constraint(schema, table, name)
      original_def = _fetch_constraint_def(schema, table, name)
      @constraint_originals[[schema, table, name]] = original_def

      cascade_def = original_def.sub(/ON DELETE \w+(\s+\w+)?/, "").strip
      cascade_def = "#{cascade_def} ON DELETE CASCADE"

      # puts "Flipping #{schema}.#{table}.#{name} to CASCADE"
      @db.execute(%(ALTER TABLE "#{schema}"."#{table}" DROP CONSTRAINT "#{name}"))
      @db.execute(%(ALTER TABLE "#{schema}"."#{table}" ADD CONSTRAINT "#{name}" #{cascade_def}))
    end

    def restore_constraint(schema, table, name)
      original_def = @constraint_originals[[schema, table, name]]
      # puts "Restoring #{schema}.#{table}.#{name}"
      @db.execute(%(ALTER TABLE "#{schema}"."#{table}" DROP CONSTRAINT "#{name}"))
      @db.execute(%(ALTER TABLE "#{schema}"."#{table}" ADD CONSTRAINT "#{name}" #{original_def}))
    end

    def truncate(schema, tbl)
      @db.execute("DELETE FROM #{schema}.#{tbl} CASCADE")
    end

    def each_fk_constraint
      @_all_fks ||= self._all_fks
      @_all_fks.each do |schema, tables|
        tables.each do |tbl, cons|
          cons.each do |con|
            yield schema, tbl, con
          end
        end
      end
    end

    # Return the tables and their FK constraint names to switch to CASCADE,
    # and then back to RESTRICT.
    def _all_fks
      d1 = self._find_all_join_table_fks
      d2 = self._model_fks
      d1.deep_merge!(d2)
      return d1
    end

    def _find_all_join_table_fks
      join_tables = []
      Sequel::Model.descendants.reject(&:anonymous?).each do |model|
        model.association_reflections.each_value do |opts|
          join_tables << opts[:join_table] if opts[:join_table]
        end
      end
      constraint_infos = @db.fetch(<<~SQL, table_names: join_tables.map(&:to_s)).all
        SELECT
          n.nspname AS schema,
          t.relname AS table_name,
          c.conname AS constraint_name
        FROM pg_constraint c
        JOIN pg_class t ON t.oid = c.conrelid
        JOIN pg_namespace n ON n.oid = t.relnamespace
        WHERE c.contype = 'f'
          AND t.relname IN :table_names
        ORDER BY t.relname, c.conname
      SQL

      result = {}
      constraint_infos.each do |row|
        tblmap = result[row[:schema]] ||= {}
        fks = tblmap[row[:table_name]] ||= []
        fks << row[:constraint_name]
      end
      return result
    end

    # This list was figured out by finding all "# Foreign key constraints:",
    # and then grabbing the FK constraints that should be cascaded on delete.
    def _model_fks
      return {
        public: {
          images: [
            :images_mobility_trip_id_fkey,
          ],
          charges: [
            :charges_member_id_fkey,
          ],
          members: [
            :members_legal_entity_id_fkey,
          ],
          anon_proxy_vendor_account_messages: [
            :anon_proxy_vendor_account_messages_outbound_delivery_id_fkey,
          ],
          commerce_carts: [ # TODO: migration
            :commerce_carts_member_id_fkey,
          ],
          commerce_cart_items: [ # TODO: migration
            :commerce_cart_items_cart_id_fkey,
            :commerce_cart_items_product_id_fkey,
          ],
          commerce_checkouts: [
            :commerce_checkouts_bank_account_id_fkey,
            :commerce_checkouts_card_id_fkey,
            :commerce_checkouts_cart_id_fkey,
          ],
          commerce_checkout_items: [
            :commerce_checkout_items_cart_item_id_fkey,
          ],
          commerce_orders: [
            :commerce_orders_checkout_id_fkey,
          ],
          commerce_order_audit_logs: [
            :commerce_order_audit_logs_order_id_fkey, # TODO: migration
          ],
          marketing_sms_dispatches: [
            :marketing_sms_dispatches_member_id_fkey,
          ],
          member_reset_codes: [
            :member_reset_codes_message_delivery_id_fkey,
          ],
          message_preferences: [
            :message_preferences_member_id_fkey,
          ],
          mobility_trips: [
            :mobility_trips_member_id_fkey,
          ],
          organization_memberships: [
            :organization_memberships_member_id_fkey,
          ],
          organization_membership_verifications: [
            :organization_membership_verifications_membership_id_fkey, # TODO: migrate
          ],
          payment_accounts: [
            :payment_accounts_member_id_fkey,
          ],
          payment_bank_accounts: [
            :bank_accounts_legal_entity_id_fkey,
          ],
          payment_cards: [
            :payment_cards_legal_entity_id_fkey,
          ],
          payment_off_platform_strategies: [
            :payment_off_platform_strategies_created_by_id_fkey,
          ],
          payment_book_transactions: [
            :payment_book_transactions_originating_ledger_id_fkey,
            :payment_book_transactions_receiving_ledger_id_fkey,
          ],
          payment_funding_transactions: [
            :payment_funding_transactions_fake_strategy_id_fkey,
            :payment_funding_transactions_increase_ach_strategy_id_fkey,
            :payment_funding_transactions_off_platform_strategy_id_fkey,
            :payment_funding_transactions_originated_book_transaction_i_fkey,
            :payment_funding_transactions_originating_payment_account_i_fkey,
            :payment_funding_transactions_platform_ledger_id_fkey,
            :payment_funding_transactions_reversal_book_transaction_id_fkey,
            :payment_funding_transactions_stripe_card_strategy_id_fkey,
          ],
          payment_ledgers: [
            :payment_ledgers_account_id_fkey,
          ],
          payment_payout_transactions: [
            :payment_payout_transactions_crediting_book_transaction_id_fkey,
            :payment_payout_transactions_fake_strategy_id_fkey,
            :payment_payout_transactions_off_platform_strategy_id_fkey,
            :payment_payout_transactions_originated_book_transaction_id_fkey,
            :payment_payout_transactions_originating_payment_account_id_fkey,
            :payment_payout_transactions_platform_ledger_id_fkey,
            :payment_payout_transactions_refunded_funding_transaction_i_fkey,
            :payment_payout_transactions_reversal_book_transaction_id_fkey,
            :payment_payout_transactions_stripe_charge_refund_strategy__fkey,
          ],
          payment_triggers: [
            :payment_triggers_originating_ledger_id_fkey,
          ],
          payment_funding_transaction_increase_ach_strategies: [
            :payment_funding_transaction_in_originating_bank_account_id_fkey,
          ],
          payment_funding_transaction_stripe_card_strategies: [
            :payment_funding_transaction_stripe_car_originating_card_id_fkey,
          ],
          payment_trigger_executions: [
            :payment_trigger_executions_book_transaction_id_fkey,
          ],
          uploaded_files: [
            :uploaded_files_created_by_id_fkey,
          ],
        },
      }
    end

    # Tables which should be entirely truncated.
    def tables_to_truncate
      return {
        public: [
          :message_deliveries,
          :member_reset_codes,
          :member_sessions,
          :member_activities, # these could contain data from members, so clear them out
          :organization_registration_links,
          :support_notes,
          :support_tickets,

          # These are unmodeled legacy and/or auxilliary tables
          # which we should trash.
          :member_survey_answers,
          :member_survey_questions,
          :member_surveys,
        ],
      }
    end

    def delete_selective
      _delete_legal_entities
      _delete_addresses
    end

    def _delete_legal_entities
      to_keep = Suma::Member.where(roles: Suma::Role.where(name: "admin")).select(:legal_entity_id)
      Suma::LegalEntity.exclude(id: to_keep).delete
    end

    def _delete_addresses
      to_keep = Suma::LegalEntity.dataset.select(:address_id).
        union(Suma::Commerce::OfferingFulfillmentOption.dataset.select(:address_id))
      Suma::Address.exclude(id: to_keep).delete
    end

    def truncate_analytics
      Suma::Analytics::Model.descendants.reject(&:anonymous?).each do |m|
        m.dataset.delete
      end
    end
  end
end
