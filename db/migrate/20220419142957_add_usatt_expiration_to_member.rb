class AddUsattExpirationToMember < ActiveRecord::Migration[5.1]
  def change
    add_column :members, :usatt_expiration, :date
  end
end
