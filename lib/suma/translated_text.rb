# frozen_string_literal: true

require "sequel/sequel_translated_text"
require "suma/postgres/model"

class Suma::TranslatedText < Suma::Postgres::Model(:translated_texts)
  include SequelTranslatedText::Model

  dataset_module do
    # Return a dataset with a full_text_search on a supported lang column like :en or :es.
    def search(col, q)
      pglang = case col
        when :en
          "english"
        when :es
          "spanish"
        else
          raise ArgumentError, "invalid column name: #{col}"
      end
      return self.full_text_search(
        :"#{col}_tsvector",
        q,
        to_tsquery: :websearch,
        rank: true,
        language: pglang,
        tsvector: true,
      )
    end

    # Return a dataset limited to translations unique on the given column,
    # and then searched with full text search.
    def distinct_search(col, q)
      # Perform a subselect since otherwise we can't sort with distinct.
      all_unique = Suma::TranslatedText.dataset.distinct(col)
      return self.where(id: all_unique.select(:id)).search(col, q)
    end
  end
end

# Table: translated_texts
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id          | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at  | timestamp with time zone | NOT NULL DEFAULT now()
#  en          | text                     | NOT NULL DEFAULT ''::text
#  es          | text                     | NOT NULL DEFAULT ''::text
#  en_tsvector | tsvector                 | NOT NULL DEFAULT to_tsvector('english'::regconfig, en)
#  es_tsvector | tsvector                 | NOT NULL DEFAULT to_tsvector('spanish'::regconfig, es)
# Indexes:
#  translated_texts_pkey | PRIMARY KEY btree (id)
#  en_tsvector_idx       | gin (en_tsvector)
#  es_tsvector_idx       | gin (es_tsvector)
# Referenced By:
#  anon_proxy_vendor_configurations      | anon_proxy_vendor_configurati_linked_success_instructions__fkey | (linked_success_instructions_id) REFERENCES translated_texts(id)
#  anon_proxy_vendor_configurations      | anon_proxy_vendor_configurations_instructions_id_fkey           | (instructions_id) REFERENCES translated_texts(id)
#  charge_line_item_self_datas           | charge_line_item_self_datas_memo_id_fkey                        | (memo_id) REFERENCES translated_texts(id)
#  commerce_offering_fulfillment_options | commerce_offering_fulfillment_options_description_id_fkey       | (description_id) REFERENCES translated_texts(id)
#  commerce_offerings                    | commerce_offerings_description_id_fkey                          | (description_id) REFERENCES translated_texts(id)
#  commerce_offerings                    | commerce_offerings_fulfillment_confirmation_id_fkey             | (fulfillment_confirmation_id) REFERENCES translated_texts(id)
#  commerce_offerings                    | commerce_offerings_fulfillment_instructions_id_fkey             | (fulfillment_instructions_id) REFERENCES translated_texts(id)
#  commerce_offerings                    | commerce_offerings_fulfillment_prompt_id_fkey                   | (fulfillment_prompt_id) REFERENCES translated_texts(id)
#  commerce_products                     | commerce_products_description_id_fkey                           | (description_id) REFERENCES translated_texts(id)
#  commerce_products                     | commerce_products_name_id_fkey                                  | (name_id) REFERENCES translated_texts(id)
#  images                                | images_caption_id_fkey                                          | (caption_id) REFERENCES translated_texts(id)
#  payment_book_transactions             | payment_book_transactions_memo_id_fkey                          | (memo_id) REFERENCES translated_texts(id)
#  payment_funding_transactions          | payment_funding_transactions_memo_id_fkey                       | (memo_id) REFERENCES translated_texts(id)
#  payment_ledgers                       | payment_ledgers_contribution_text_id_fkey                       | (contribution_text_id) REFERENCES translated_texts(id)
#  payment_payout_transactions           | payment_payout_transactions_memo_id_fkey                        | (memo_id) REFERENCES translated_texts(id)
#  payment_triggers                      | payment_triggers_memo_id_fkey                                   | (memo_id) REFERENCES translated_texts(id)
#  payment_triggers                      | payment_triggers_receiving_ledger_contribution_text_id_fkey     | (receiving_ledger_contribution_text_id) REFERENCES translated_texts(id)
#  programs                              | programs_app_link_text_id_fkey                                  | (app_link_text_id) REFERENCES translated_texts(id)
#  programs                              | programs_description_id_fkey                                    | (description_id) REFERENCES translated_texts(id)
#  programs                              | programs_name_id_fkey                                           | (name_id) REFERENCES translated_texts(id)
#  vendible_groups                       | vendible_groups_name_id_fkey                                    | (name_id) REFERENCES translated_texts(id)
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
