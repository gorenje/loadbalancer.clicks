require 'pty'

module PaperTrail
  module Helpers
    extend self

    def stream_out(cmd)
      begin
        PTY.spawn( cmd ) do |stdout, stdin, pid|
          begin
            stdout.each { |line| print line }
          rescue Errno::EIO
            puts "Errno:EIO error, but this probably just means " +
              "that the process has finished giving output"
          end
        end
      rescue PTY::ChildExited
        puts "The child process exited!"
      end
    end
  end
end

namespace :papertrail do
  desc <<-EOF
    Scan the papertrail logs for slow deletes in the last 3 days.
  EOF
  task :slow_deletes do
    d = (Date.today - 3).strftime("%Y/%m/%d")
    cmd="papertrail --min-time \"#{d} 01:00 +01:00\" duration "+
      "| awk '// { print substr($0, 0, 180); }' | grep delete"
    PaperTrail::Helpers.stream_out(cmd)
  end

  desc <<-EOF
    Slow queries in the last 3 days taking > 100 seconds.
  EOF
  task :slow_queries_gt_100s do
    d = (Date.today - 3).strftime("%Y/%m/%d")
    cmd="papertrail --min-time \"#{d} 01:00 +01:00\" duration | "+
      "awk '// { print substr($0, 0, 180); }' | "+
      "egrep -v \": [0-9]{4,5}[.][0-9]{3} ms\""
    PaperTrail::Helpers.stream_out(cmd)
  end

  desc <<-EOF
    Slow queries in the last 3 days taking < 100 seconds.
  EOF
  task :slow_queries_lt_100s do
    d = (Date.today - 3).strftime("%Y/%m/%d")
    cmd="papertrail --min-time \"#{d} 01:00 +01:00\" duration | "+
      "awk '// { print substr($0, 0, 180); }' | "+
      "egrep \": [0-9]{3,5}[.][0-9]{3} ms\""
    PaperTrail::Helpers.stream_out(cmd)
  end

end
