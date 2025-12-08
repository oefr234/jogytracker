class CreateTimeEntries < ActiveRecord::Migration[7.1]
  def change
    create_table :time_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.date :date, null: false
      t.decimal :distance_km, precision: 5, scale: 2, null: false # up to 999.99 if you adjust precision
      t.integer :duration_seconds, null: false

      t.timestamps
    end
    add_index :time_entries, :date
  end
end
