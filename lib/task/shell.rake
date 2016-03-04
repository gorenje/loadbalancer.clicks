desc "Start a pry shell and load all gems"
task :shell => :environment do
  require 'pry'
  require 'term/ansicolor'
  require 'highline/import'
  Pry.editor = "emacs"
  Pry.start
end

desc "The same as 'rails console' but for sinatra"
task :console => :shell
