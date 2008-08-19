class Merb < Thor

  MERB_REPOS = ["merb-core", "merb-more", "merb-plugins"] unless defined? MERB_REPOS
  EXTLIB_REPO = 'git://github.com/sam/extlib.git'

  desc "clone", "clone the 3 main merb repositories"
  def clone
    if File.exists?("merb")
      puts("./merb already exists!")
      exit
    end
    require "fileutils"
    FileUtils.mkdir("merb")
    FileUtils.cd("merb")
    MERB_REPOS.each {|r| system("git clone git://github.com/wycats/#{r}.git") }
    unless File.exists?("extlib")
      system("git clone #{EXTLIB_REPO}")
    end
  end

  desc 'update', 'Update your local Merb repositories.  Run from inside the top-level merb directory.'
  def update
    MERB_REPOS.each do |r|
      unless File.exists?(r)
        puts("#{r} missing ... did you use merb:clone to set this up?")
        exit
      end
    end
    MERB_REPOS.each do |r|
      FileUtils.cd(r) do
        system %{
          git fetch
          git checkout master
          git rebase origin/master
        }
      end
    end
    unless File.exists?("extlib")
      puts("extlib missing ... did you use merb:clone to set this up?")
      exit
    end
    FileUtils.cd("extlib")
    system %{
      git fetch
      git checkout master
      git rebase origin/master
    }
  end

  desc 'install', 'Install merb-core and merb-more'
  def install
    install = Install.new
    install.extlib
    install.core
    install.more
  end

  class Gems < Thor
    desc 'wipe', 'Uninstall all RubyGems related to Merb'
    def wipe
      windows = PLATFORM =~ /win32|cygwin/ rescue nil
      sudo = windows ? ("") : ("sudo")
      `gem list merb`.split("\n").each do |line|
        next unless line =~ /^(merb[^ ]+)/
        system("#{sudo} gem uninstall -a -i -x #{$1}")
      end
      system("#{sudo} gem uninstall -a -i -x extlib")
    end

    desc 'refresh', 'Pull fresh copies of Merb and refresh all the gems'
    def refresh
      merb = Merb.new
      merb.update
      merb.install
    end
  end

  class Install < Thor
    desc 'core', 'Install merb-core'
    def core
      FileUtils.cd("merb-core") { system("rake install") }
    end

    desc 'more', 'Install merb-more'
    def more
      FileUtils.cd("merb-more") { system("rake install") }
    end

    desc 'plugins', 'Install merb-plugins'
    def plugins
      FileUtils.cd("merb-plugins") { system("rake install") }
    end

    desc 'extlib', 'Install extlib'
    def extlib
      FileUtils.cd("extlib") { system("rake install") }
    end
  end
end