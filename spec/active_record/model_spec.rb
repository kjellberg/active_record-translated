# frozen_string_literal: true

require "spec_helper"
require "shoulda/matchers"

RSpec.describe "Model", type: :model do
  subject(:post) { create(:post) }

  before do # reset locale to default settings
    I18n.locale = :en
    ActiveRecord::Translated.locale = nil
  end

  describe "does not break validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:slug) }
    it { should validate_uniqueness_of(:slug) }
  end

  context "when fetching a record by PRIMARY KEY" do
    it "ignores locale config" do
      post_es = create(:post, locale: :es)
      expect(Post.find(post_es.id)).to eq(post_es)
    end
  end

  context "when fetching a record by RECORD ID" do
    it "finds the correct translation" do
      record_id = ActiveRecord::Translated.generate_record_id
      create(:post, title: "Svenska", locale: :sv, record_id: record_id)
      create(:post, title: "Espanol", locale: :es, record_id: record_id)
      create(:post, title: "English", locale: :en, record_id: record_id)

      ActiveRecord::Translated.locale = :es
      expect(Post.find(record_id).title).to eq("Espanol")
    end

    it "raises RecordNotFound error if current translation does not exist" do
      record_id = ActiveRecord::Translated.generate_record_id
      create(:post, title: "English", locale: :en, record_id: record_id)

      ActiveRecord::Translated.locale = :pt
      expect { Post.find(record_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when creating a new record" do
    it { expect(post.locale).to eq("en") }
    it { expect(ActiveRecord::Translated.record_id?(post.record_id)).to be(true) }

    it "assigns the current locale to record" do
      I18n.locale = :sv
      post = Post.create(title: "Ett inl\u00E4gg", slug: "ett-inl\u00E4gg")
      expect(post.locale).to eq("sv")
    end

    it "prioritizes ActiveRecord::Translated#locale over I18n#locale" do
      I18n.locale = :sv
      ActiveRecord::Translated.locale = :pt
      post = Post.create(title: "foo", slug: "bar")
      expect(post.locale).to eq("pt")
    end

    it "prioritizes locale attribute over ActiveRecord::Translated#locale" do
      I18n.locale = :sv
      ActiveRecord::Translated.locale = :pt
      post = Post.create(title: "foo", slug: "bar", locale: :fi)
      expect(post.locale).to eq("fi")
    end
  end

  context "when translating an existing record" do
    it "shares record_id with its associatied records" do
      ActiveRecord::Translated.locale = :es
      post_es = Post.create(title: "Una entrada de blog")
      post_sv = Post.create(title: "Ett blogginlägg", locale: :sv)

      # Associate the translations with each other
      post_es.translations << post_sv

      expect(post_es.record_id).to eq(post_sv.record_id)
    end

    it "can count the number of translations with #translation.count" do
      record_id = ActiveRecord::Translated.generate_record_id
      post = create(:post, record_id: record_id, locale: :en)
      post.translations << create(:post, locale: :pt)
      post.translations << create(:post, locale: :sv)
      post.translations << create(:post, locale: :es)

      expect(post.translations.count).to eq(4)
    end

    # rubocop:disable RSpec/MultipleExpectations
    it "includes translations in #translations" do
      post = create(:post, locale: :en)
      post_pt = create(:post, locale: :pt)
      post.translations << post_pt

      expect(post.translations).to include(post_pt)
      expect(post_pt.translations).to include(post)
    end
    # rubocop:enable RSpec/MultipleExpectations

    it "does not allow duplicates" do
      post = create(:post, title: "おはよう", locale: :ja)
      duplicate = create(:post, title: "おはようございます", locale: :ja)

      expect { post.translations << duplicate }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  context "when editing a translation" do
    it "is possible to update locale attribute manually" do
      manual_post = Post.create(title: "Foo", slug: "bar", locale: :es)
      manual_post.update(locale: :pt)

      expect(manual_post.locale).to eq("pt")
    end
  end

  describe "default_scope" do
    let!(:record_id) { ActiveRecord::Translated.generate_record_id }
    let(:post_sv) { create(:post, title: "Godmorgon", record_id: record_id, locale: :sv) }
    let(:post_es) { create(:post, title: "Buenos dias", record_id: record_id, locale: :es) }
    let(:post_mt) { create(:post, title: "Bongu", record_id: record_id, locale: :mt) }

    before do
      create_list(:post, 5, locale: :fi)
      create_list(:post, 6, locale: :de)
      create_list(:post, 7, locale: :no)
      create_list(:post, 18, locale: :sv)
      create_list(:post, 20, locale: :en)
    end

    it "includes matching translations" do
      ActiveRecord::Translated.locale = :sv
      expect(Post.all).to include(post_sv)
    end

    it "excludes non-matching translations" do
      ActiveRecord::Translated.locale = :sv
      expect(Post.all).not_to include(post_es)
    end

    it "scopes results by locale" do
      ActiveRecord::Translated.with_locale(:de) do
        expect(Post.count).to eq(6)
      end
    end

    it "with non-matching locale" do
      ActiveRecord::Translated.locale = :pt
      expect(Post.count).to eq(0)
    end
  end

  describe "#unscoped_locale" do
    it "can count the number of translations by record_id" do
      record_id = ActiveRecord::Translated.generate_record_id
      post = create(:post, record_id: record_id, locale: :en)
      post.translations << create(:post, locale: :pt)
      post.translations << create(:post, locale: :sv)
      post.translations << create(:post, locale: :es)
      create(:post, locale: :en)
      create(:post, locale: :pt)

      expect(Post.unscoped_locale.where(record_id: record_id).count).to eq(4)
    end

    it "can count the total number of records" do
      create(:post, locale: :en)
      create(:post, locale: :pt)
      create(:post, locale: :sv)
      create(:post, locale: :es)

      expect(Post.unscoped_locale.count).to eq(4)
    end
  end
end
