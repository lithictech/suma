# frozen_string_literal: true

module Suma::Analytics
  class << self
    def olap_classes = Suma::Analytics::Model.descendants.reject(&:anonymous?)

    # Given an OLTP model instances (like a Suma::Member),
    # upsert them into all corresponding analytics tables.
    # All instances in +oltp_models+ must have the same type.
    def upsert_from_transactional_model(oltp_models, olap_classes: nil)
      oltp_models = Suma.as_ary(oltp_models)
      return nil if oltp_models.empty?
      uniq_oltp_classes = oltp_models.map(&:class).uniq
      raise Suma::InvalidPrecondition, "models must all be the same type, got: #{uniq_oltp_classes.map(&:name)}" unless
        uniq_oltp_classes.count == 1
      model_cls = oltp_models.first.class.first.class
      eligible_olap_classes = self.olap_classes.select { |d| d.denormalize_from?(model_cls) }
      olap_classes = olap_classes.nil? ? eligible_olap_classes : (olap_classes & eligible_olap_classes)
      return nil if olap_classes.empty?
      row_groups = SequelTranslatedText.language(SequelTranslatedText.default_language) do
        olap_classes.map do |olap_cls|
          oltp_models.flat_map { |o| olap_cls.to_rows(o) }
        end
      end
      upserting = olap_classes.zip(row_groups)
      upserting.each { |(m, rows)| m.upsert_rows(*rows) }
      return upserting
    end

    # Destroy analytics rows that are based on the given model class and ids.
    # For example, [Suma::Member, 1] would destroy Suma::Analytics::Member rows with a member_id of 1.
    def destroy_from_transactional_model(oltp_class, ids)
      olap_classes = self.olap_classes.select { |d| d.destroy_from?(oltp_class) }
      olap_classes.each { |m| m.destroy_rows(ids) }
    end

    # Upsert all data from all transactional classes that are denormalized.
    # Importing is designed to be as efficient as possible, but is still pretty slow.
    # Usually you'd use this after a +truncate_all+, or adding new columns to an analytics table.
    #
    # @param oltp_classes [Array<Class>,Class] Reimport analytics models depend on any of these classes.
    #   All rows are imported. If nil, use all oltp classes that olap classes depend on.
    #   For example, using +oltp_classes+ of +Suma::Order
    #   will process +Suma::Analytics::Member+ and +Suma::Analytics::Order+.
    # @param olap_classes [Array<Class>,Class] Reimport these analytics models only.
    #   All oltp classe that these olap models depend on will be loaded and imported.
    #   For example, using +olap_classes+ of +Suma::Analytics::Member+ will process all members and orders.
    def reimport_all(oltp_classes: nil, olap_classes: nil)
      olap_classes ||= self.olap_classes
      olap_classes = Suma.as_ary(olap_classes)
      oltp_classes ||= olap_classes.flat_map(&:denormalizing_from).uniq
      oltp_classes = Suma.as_ary(oltp_classes)
      oltp_classes.each do |oltp_cls|
        oltp_cls.dataset.each_cursor_page(yield_page: true) do |rows|
          self.upsert_from_transactional_model(rows, olap_classes:)
        end
      end
    end

    def truncate_all
      self.olap_classes.each { |m| m.truncate(cascade: true) }
    end
  end
end
