# frozen_string_literal: true

require "active_record/translated/version"
require "active_record/translated/engine"

require "dry-configurable"
require "request_store"
require "securerandom"

module ActiveRecord
  module Translated
    extend Dry::Configurable

    # Defaults to nil if no default value is given
    setting :default_locale, default: nil

    autoload :Model, "active_record/translated/model"

    class << self
      def generate_record_id
        SecureRandom.uuid
      end

      def locale
        read_locale || config.default_locale || I18n.locale
      end

      def locale=(locale)
        set_locale(locale)
      end

      def with_locale(locale)
        previous_locale = read_locale
        begin
          set_locale(locale)
          yield(locale)
        ensure
          set_locale(previous_locale)
        end
      end
      # @!endgroup

      protected

      def read_locale
        storage[:art_locale]
      end

      # rubocop:disable Naming/AccessorMethodName
      def set_locale(locale)
        locale = locale.to_sym if locale.is_a?(String)
        storage[:art_locale] = locale
      end
      # rubocop:enable Naming/AccessorMethodName

      def storage
        RequestStore.store
      end
    end
  end
end