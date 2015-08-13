class CreateLists < ActiveRecord::Migration
  def up
    create_table :ror_maily_lists do |t|
      t.string            :name,                                        null: false
      t.string            :title
      t.string            :context_name
    end

    remove_column :ror_maily_dispatches, :token_action
    remove_column :ror_maily_dispatches, :subscription_group_id
    remove_column :ror_maily_dispatches, :autosubscribe
    remove_column :ror_maily_dispatches, :start
    remove_column :ror_maily_dispatches, :start_var
    remove_column :ror_maily_dispatches, :trigger
    remove_column :ror_maily_dispatches, :enabled
    remove_column :ror_maily_dispatches, :context_name
    add_column :ror_maily_dispatches, :start_at, :text
    add_column :ror_maily_dispatches, :list_id, :integer
    add_column :ror_maily_dispatches, :state, :string, default: :disabled

    remove_column :ror_maily_subscriptions, :dispatch_id
    remove_column :ror_maily_subscriptions, :type
    add_column :ror_maily_subscriptions, :list_id, :integer
    #add_column :ror_maily_subscriptions, :next_delivery_at, :datetime

    drop_table :ror_maily_subscription_groups
    drop_table :ror_maily_aggregated_subscriptions

    rename_column :ror_maily_logs, :processed_at, :processing_at
    change_column :ror_maily_logs, :status, :string, default: nil
    add_column :ror_maily_logs, :entity_email, :string
  end
end
