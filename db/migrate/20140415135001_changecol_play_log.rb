class ChangecolPlayLog < ActiveRecord::Migration
  def up
    rename_column :play_logs, :userid, :user_id
  end

  def down
    rename_column :play_logs, :user_id, :userid
  end
end
