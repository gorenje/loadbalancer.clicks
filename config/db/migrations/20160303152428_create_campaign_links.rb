class CreateCampaignLinks < ActiveRecord::Migration
  def change
    create_table "campaign_links", :force => :cascade do |t|
      t.string  "campaign"
      t.string  "adgroup"
      t.string  "ad"
      t.string  "campaign_url", :limit => 1024
      t.json    "target_url"
      t.integer "attribution_window_fingerprint"
      t.integer "attribution_window_idfa"
      t.string  "network"
      t.string  "country"
      t.string  "device"
    end
  end
end
