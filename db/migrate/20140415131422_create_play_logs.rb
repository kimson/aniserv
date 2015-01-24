class CreatePlayLogs < ActiveRecord::Migration
  def change
    create_table :play_logs do |t|
      t.integer :movie_id
      t.integer :userid

      t.timestamps
    end
  end
end
