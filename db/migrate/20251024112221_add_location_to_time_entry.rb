class AddLocationToTimeEntry < ActiveRecord::Migration[7.1]
  def change
    add_column :time_entries, :location, :string
  end
end
