class CreateMovies < ActiveRecord::Migration
  def change
    create_table :movies do |t|
      t.string :title
      t.string :subtitle, :limit => 1024
      t.integer :number
      t.integer :special_flag
      t.integer :relation_number
      t.datetime :broadcast_time
      t.string :station
      t.string :filename
      t.string :syobocalid

      t.timestamps
    end
  end
end
