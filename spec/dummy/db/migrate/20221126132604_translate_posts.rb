# frozen_string_literal: true

class TranslatePosts < ActiveRecord::Migration[5.2]
  def change
    add_column :posts, :locale, :string
    add_column :posts, :record_id, :string

    add_index :posts, :locale
    add_index :posts, :record_id
    add_index :posts, %i[locale record_id], unique: true
  end
end
