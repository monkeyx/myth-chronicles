class AddAdminUserFlag < ActiveRecord::Migration
  def change
  	add_column :users, :admin, :boolean, default: false
  	add_index :users, [:email, :admin], name: 'idx_admin_users'
  end
end
