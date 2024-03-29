class CreateSites < ActiveRecord::Migration
  def self.up
    create_table :sites do |t|
      t.text :hash
      t.text :url
      t.text :html

      t.timestamps
    end
  end

  def self.down
    drop_table :sites
  end
end
