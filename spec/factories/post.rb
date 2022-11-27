# frozen_string_literal: true

FactoryBot.define do
  factory :post do
    sequence :title do |n|
      "Post #{n}"
    end

    sequence :slug do |n|
      "post-#{n}"
    end
  end
end
