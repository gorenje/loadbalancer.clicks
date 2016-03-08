$refresh_cam_lnk_cache = Proc.new do
  $cam_lnk_cache = Hash[CampaignLink.all.to_a.map { |c| [c.id, c]}] rescue {}
end
