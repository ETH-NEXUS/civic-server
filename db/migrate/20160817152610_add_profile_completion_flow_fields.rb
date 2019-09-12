class AddProfileCompletionFlowFields < ActiveRecord::Migration[4.2]
  def change
    rename_column :users, :accepted_license_term, :accepted_license
    add_column :users, :signup_complete, :boolean
  end
end
