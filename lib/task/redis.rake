namespace :redis do
  namespace :clicks do
    desc <<-EOF
      Show some details of the current details.
    EOF
    task :show_keys => :environment do
      queue         = RedisQueue.new($clickstore_redis)

      while true
        all_keys_seen = Set.new

        queue.show.each do |clk|
          clk.keys.each { |k| all_keys_seen << k }
        end

        puts("="*40)
        all_keys_seen.each do |key|
          puts "# #{key}"
        end
        sleep 1
      end
    end
  end
end
