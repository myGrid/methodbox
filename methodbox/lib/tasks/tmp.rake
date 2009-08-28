namespace :tmp do
  namespace :assets do
    desc "Clears javascripts/cache and stylesheets/cache"
    task :clear => :environment do
      FileUtils.rm(Dir['public/javascripts/cache/[^.]*'])
      FileUtils.rm(Dir['public/stylesheets/cache/[^.]*'])
      FileUtils.rm(Dir['public/javascripts/js_cached*'])
      FileUtils.rm(Dir['public/stylesheets/css_cached*'])
    end
  end
end