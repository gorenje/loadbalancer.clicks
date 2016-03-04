require 'pty'
namespace :js_test do
  desc 'test'
  task :run do

    PTY.spawn("vows --spec test/jstest/tracking.coffee") do |stdin, stdout, pid|
      stdin.each { |line| print line }
    end
    system('killall phantomjs')

    PTY.spawn("vows --spec test/jstest/jstest.coffee") do |stdin, stdout, pid|
      stdin.each { |line| print line }
    end
    system('killall phantomjs')

  end
end
