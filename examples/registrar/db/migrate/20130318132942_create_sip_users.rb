class CreateSipUsers < ActiveRecord::Migration
  def change
    create_table :sip_users do |t|
      t.string :user_name
      t.string :first_name
      t.string :last_name

      t.timestamps
    end
  end
end
