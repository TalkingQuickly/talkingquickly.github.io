require "rubygems"
require "tmpdir"

require "bundler/setup"
require "jekyll"


# Change your GitHub reponame
GITHUB_REPONAME = "TalkingQuickly/talkingquickly.github.io"
DEPLOY_DIR = '/home/deploy/release'

namespace :jekyll do
  task :generate do
    desc "Generate blog files"
    system "jekyll build"
  end

  desc "Sets up folders for fast publising"
  task :publish_fast_setup  do
    pwd = Dir.pwd
    system "git clone git@github.com:#{GITHUB_REPONAME}.git #{DEPLOY_DIR}"
    Dir.chdir DEPLOY_DIR
    system "git checkout master"
    Dir.chdir pwd
  end

  desc "Publishes using a cache of the repo"
  task :publish_fast => [:generate] do
    pwd = Dir.pwd
    system "rsync -avh _site/ #{DEPLOY_DIR} --delete --exclude '.git'"
    Dir.chdir DEPLOY_DIR
    message = "Site updated at #{Time.now.utc}"
    system "touch .nojekyll"
    system "git add ."
    system "git commit -m #{message.inspect}"
    system "git push origin master"
    Dir.chdir pwd
  end

  desc "Generate and publish blog to gh-pages"
  task :publish => [:generate] do
    Dir.mktmpdir do |tmp|
      cp_r "_site/.", tmp

      pwd = Dir.pwd
      Dir.chdir tmp

      system "git init"
      system "git add ."
      message = "Site updated at #{Time.now.utc}"
      system "git commit -m #{message.inspect}"
      system "git remote add origin git@github.com:#{GITHUB_REPONAME}.git"
      system "git push origin master --force"

      Dir.chdir pwd
    end
  end
end
