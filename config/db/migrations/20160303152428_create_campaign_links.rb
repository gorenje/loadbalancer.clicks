class CreateCampaignLinks < ActiveRecord::Migration
  def change
    create_table :campaign_links do |t|
      t.string :campaign
      t.string :adgroup
      t.string :ad

      t.string :country
      t.string :device

      t.integer :attribution_window_seconds

      t.string :campaign_url, :limit => 1024
      t.string :target_url, :limit => 1024
    end
  end
end
