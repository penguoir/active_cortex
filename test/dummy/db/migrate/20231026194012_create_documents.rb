class CreateDocuments < ActiveRecord::Migration[7.0]
  def change
    create_table :documents do |t|
      t.string :text
      t.string :summary

      t.timestamps
    end
  end
end
