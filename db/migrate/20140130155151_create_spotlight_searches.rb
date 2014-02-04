class CreateSpotlightSearches < ActiveRecord::Migration
  def change
    create_table :spotlight_searches do |t|
      t.string :title
      t.text :short_description
      t.text :long_description
      t.text :query_params
      t.integer :weight
      t.boolean :on_landing_page
      t.string :featured_image
      t.references :exhibit
      t.timestamps
    end

    add_index :spotlight_searches, :exhibit_id
  end
end
