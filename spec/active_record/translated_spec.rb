# frozen_string_literal: true

require "spec_helper"

module ActiveRecord
  RSpec.describe Translated do
    after { described_class.locale = :en }

    it { expect(described_class::VERSION).to be_truthy }

    describe "#generate_record_id" do
      it do
        rid = described_class.generate_record_id
        expect(rid.match(/^[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}$\z/)).not_to be_nil
      end
    end

    # rubocop:disable RSpec/PredicateMatcher
    describe "#record_id?" do
      it { expect(described_class.record_id?("0000-0000-0000")).to be_truthy }
      it { expect(described_class.record_id?("aaaa-bbbb-cccc")).to be_truthy }
    end
    # rubocop:enable RSpec/PredicateMatcher

    describe "#locale" do
      before { described_class.locale = :es }

      it { expect(described_class.locale).to eq(:es) }
      it { expect(described_class.send("locale")).to eq(:es) }
    end

    describe "#read_locale" do
      it "gets correct locale" do
        described_class.with_locale(:es) do
          expect(described_class.send("read_locale")).to eq(:es)
        end
      end
    end

    describe "#set_locale" do
      before { described_class.send("set_locale", :sv) }

      it { expect(described_class.locale).to eq(:sv) }
    end

    describe "#with_locale" do
      it { expect(described_class.locale.to_sym).to eq(:en) }

      it "works with multiple locales" do
        described_class.with_locale(:fr) do
          expect(described_class.locale).to eq(:fr)
        end
      end

      # rubocop:disable RSpec/MultipleExpectations
      it "keeps locale within block" do
        described_class.locale = :en
        described_class.with_locale(:fr) do
          expect(described_class.locale).to eq(:fr)
        end
        expect(described_class.locale).to eq(:en)
      end
      # rubocop:enable RSpec/MultipleExpectations
    end
  end
end
