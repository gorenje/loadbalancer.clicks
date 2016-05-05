class AddUserIdToCampaignLinks < ActiveRecord::Migration
  def change
    add_column :campaign_links, :user_id, :integer
  end
end
