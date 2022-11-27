# frozen_string_literal: true

module ActiveRecord
  module Translated
    # Makes Translated available to Rails as an Engine.
    module Model
      extend ActiveSupport::Concern

      # rubocop:disable Metrics/BlockLength
      included do
        before_save :set_record_id
        before_save :set_locale

        has_many :translations, -> { global }, class_name: "Post", foreign_key: :record_id, primary_key: :record_id
        default_scope { where(locale: ActiveRecord::Translated.locale) }
        scope :global, -> { unscope(where: :locale) }

        class << self
          def find(*args)
            id = args.first

            return find_translated(id) if ActiveRecord::Translated.record_id?(id)

            super(*args)
          end

          def exists?(id)
            return super unless ActiveRecord::Translated.record_id?(id)
            return true if exists_translated?(id)

            super
          end

          private

          def find_translated(record_id, allow_nil: false)
            result = find_by(record_id: record_id)
            return result if result

            raise ActiveRecord::RecordNotFound unless allow_nil
          end

          # rubocop:disable Rails/WhereExists
          def exists_translated?(record_id)
            where(record_id: record_id, locale: ActiveRecord::Translated.locale).exists?
          end
          # rubocop:enable Rails/WhereExists
        end
      end
      # rubocop:enable Metrics/BlockLength

      def set_locale
        return if locale.present?

        self.locale = ActiveRecord::Translated.locale
      end

      def set_record_id
        return if record_id.present?

        self.record_id = ActiveRecord::Translated.generate_record_id
      end
    end
  end
end
