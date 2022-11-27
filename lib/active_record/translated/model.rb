# frozen_string_literal: true

module ActiveRecord
  module Translated
    # Makes Translated available to Rails as an Engine.
    module Model
      extend ActiveSupport::Concern

      included do
        before_save :set_record_id
        before_save :set_locale

        has_many :translations, class_name: "Post", foreign_key: :record_id, primary_key: :record_id
        scope :translated, -> { where(locale: ActiveRecord::Translated.locale) }

        class << self
          def find_translated(record_id)
            translated.find_by(record_id: record_id)
          end

          def find_translated!(record_id)
            translated.find_by!(record_id: record_id)
          end
        end
      end

      private

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
