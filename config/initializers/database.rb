require 'active_record'
require 'activerecord-import'

ActiveSupport.on_load(:active_record) do
  env = ENV['RACK_ENV']
  ActiveRecord::Base.establish_connection
  ActiveRecord::Base.logger = env == 'development' ? Logger.new(STDOUT) : nil

  puts "DB connection established for #{env}"
end
