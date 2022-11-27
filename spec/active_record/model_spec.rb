# frozen_string_literal: true

require "spec_helper"
require "shoulda/matchers"

RSpec.describe "Model", type: :model do
  subject(:post) { create(:post) }

  let!(:record_id) { ActiveRecord::Translated.generate_record_id }

  let!(:post_sv) { create(:post, title: "Godmorgon", record_id: record_id, locale: :sv) }
  let!(:post_es) { create(:post, title: "Buenos dias", record_id: record_id, locale: :es) }
  let!(:post_mt) { create(:post, title: "Bongu", record_id: record_id, locale: :mt) }

  after { ActiveRecord::Translated.locale = :en }

  describe "does not break validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:slug) }
    it { should validate_uniqueness_of(:slug) }
  end

  describe "gem specific model attributes" do
    it { expect(post.locale).to eq(ActiveRecord::Translated.locale.to_s) }
    it { expect(post.record_id).to be_truthy }
  end

  describe "#create" do
    it "sets locale to 'en' by default" do
      expect(post.locale).to eq("en")
    end

    it "assigns the correct locale" do
      ActiveRecord::Translated.locale = :sv
      sv_post = Post.create(title: "Ett inl\u00E4gg", slug: "ett-inl\u00E4gg")

      expect(sv_post.locale).to eq("sv")
    end

    it "prioritises locale attribute over config" do
      ActiveRecord::Translated.locale = :en
      manual_post = Post.create(title: "Foo", slug: "bar", locale: "es")

      expect(manual_post.locale).to eq("es")
    end
  end

  describe "#update" do
    it "is possible to update locale attribute manually" do
      manual_post = Post.create(title: "Foo", slug: "bar")
      manual_post.update(locale: :es)

      expect(manual_post.locale).to eq("es")
    end
  end

  context "with shared record_id" do
    it { expect(post_sv.record_id).to eq(record_id) }
    it { expect(post_es.record_id).to eq(record_id) }
    it { expect(post_mt.record_id).to eq(record_id) }
    it { expect(Post.global.where(record_id: record_id).count).to eq(3) }
  end

  describe "#translations" do
    it { expect(post_sv.translations.count).to eq(3) }
    it { expect(post_es.translations).to include(post_mt) }
    it { expect(post_es.translations).to include(post_es) }

    it "autofills record_id" do
      post_fr = Post.new(title: "Bonjour", locale: :fr)
      post_sv.translations << post_fr
      post_sv.save

      expect(post_fr.record_id).to eq(record_id)
    end

    it "does not allow duplicates" do
      post.translations << create(:post, title: "おはよう", locale: :ja)
      duplicate = create(:post, title: "おはようございます", locale: :ja)

      expect { post.translations << duplicate }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "#find" do
    context "with primary key" do
      it "does not break find" do
        ActiveRecord::Translated.locale = :sv
        expect(Post.find(post.id)).to eq(post)
      end
    end

    context "with resource_id" do
      it "with gem set locale" do
        ActiveRecord::Translated.locale = :es
        match = Post.find(record_id)

        expect(match.title).to eq("Buenos dias")
      end
    end

    it "with locale wrapper" do
      ActiveRecord::Translated.locale = :sv
      match = ActiveRecord::Translated.with_locale(:mt) do
        Post.find(record_id)
      end

      expect(match.title).to eq("Bongu")
    end

    it "with non-matching locale" do
      ActiveRecord::Translated.locale = :pt

      expect { Post.find(record_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "default_scope" do
    it "is ignored by #find when searching by ID" do
      ActiveRecord::Translated.locale = :pt
      expect(Post.all.find(post.id)).not_to be_nil
    end

    it "includes matching translations" do
      ActiveRecord::Translated.locale = :sv
      expect(Post.all).to include(post_sv)
    end

    it "excludes non-matching translations" do
      ActiveRecord::Translated.locale = :sv
      expect(Post.all).not_to include(post_es)
    end

    it "with non-matching locale" do
      ActiveRecord::Translated.locale = :pt
      expect(Post.all.count).to eq(0)
    end

    context "with multiple results" do
      before do
        create_list(:post, 5, locale: :fi)
        create_list(:post, 6, locale: :de)
        create_list(:post, 7, locale: :no)
      end

      it "displays translated results" do
        ActiveRecord::Translated.with_locale(:de) do
          expect(Post.all.count).to eq(6)
        end
      end
    end
  end
end
