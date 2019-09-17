class DropSessionsTable < ActiveRecord::Migration[5.0]
  def change
    drop_table :sessions do |t|
      t.string :session_id, null: false
      t.text :data
      t.timestamps
    end
  end
end
