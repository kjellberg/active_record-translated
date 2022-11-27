# frozen_string_literal: true

class CreatePosts < ActiveRecord::Migration[5.2]
  def change
    create_table :posts do |t|
      t.string :title, nullable: false
      t.string :slug, nullable: false
      t.text :description, nullable: true
      t.timestamps
    end

    add_index :posts, :slug, unique: true
  end
end
