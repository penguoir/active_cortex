class CreateReviews < ActiveRecord::Migration[7.0]
  def change
    create_table :reviews do |t|
      t.string :content, null: false
      t.integer :rating, null: false
      t.references :book, null: false, foreign_key: true

      t.timestamps
    end
  end
end
