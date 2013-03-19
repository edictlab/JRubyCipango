class CreateRegistrations < ActiveRecord::Migration
  def change
    create_table :registrations do |t|
      t.string :location
      t.references :sip_user

      t.timestamps
    end
    add_index :registrations, :sip_user_id
  end
end
