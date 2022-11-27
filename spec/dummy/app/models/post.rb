# frozen_string_literal: true

class Post < ApplicationRecord
  include ActiveRecord::Translated::Model

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
end
