#!/usr/local/bin/ruby

class Merb < Thor

  MERB_REPOS = ["merb-core", "merb-more", "merb-plugins"] unless defined? MERB_REPOS
  EXTLIB_REPO = 'git://github.com/sam/extlib.git'

  desc "clone", "clone the 3 main merb repositories"
  def clone
    require "fileutils"

    unless File.exists?('merb')
      puts "Creating merb dir..."
      FileUtils.mkdir("merb")
    end

    FileUtils.cd("merb")

    MERB_REPOS.each do |r|
      if File.exists?(r)
        puts "\n#{r} repos exists! Updating instead of cloning..."
        FileUtils.cd(r) do
          system %{
            git fetch
            git checkout master
            git rebase origin/master
          }
        end
      else
        puts "\nCloning #{r} repos..."
        system("git clone git://github.com/wycats/#{r}.git")
      end
    end

    if File.exists?("extlib")
      puts "\nextlib repo exists! Updating instead of cloning..."
      FileUtils.cd('extlib') do
        system %{
          git fetch
          git checkout master
          git rebase origin/master
        }
      end
    else
      puts "\nCloning extlib repos..."
      system("git clone #{EXTLIB_REPO}")
    end
  end

  desc 'update', 'Update your local Merb repositories.  Run from outside the top-level merb directory.'
  def update
    check_for_dir('./merb')
    Merb.new.clone
  end

  desc 'install', 'Install extlib, merb-core, and merb-more'
  def install
    install = Install.new

    check_for_dir('./extlib')
    install.extlib

    check_for_dir('./merb-core')
    install.core

    check_for_dir('./merb-more')
    install.more
  end

  class Gems < Thor
    desc 'wipe', 'Uninstall all RubyGems related to Merb'
    def wipe
      windows = PLATFORM =~ /win32|cygwin/ rescue nil
      sudo = windows ? "" : "sudo"
      `gem list merb`.split("\n").each do |line|
        next unless line =~ /^(merb[^ ]+)/
        system("#{sudo} gem uninstall #{$1} -a -i -x; true")
      end
      system("#{sudo} gem uninstall extlib -a -i -x")
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
      install_gem "merb-core"
    end

    desc 'more', 'Install merb-more'
    def more
      install_gem "merb-more"
    end

    desc 'plugins', 'Install merb-plugins'
    def plugins
      install_gem "merb-plugins"
    end

    desc 'extlib', 'Install extlib'
    def extlib
      install_gem "extlib"
    end

    private

    def install_gem(gem)
      FileUtils.cd(gem) { system("rake install") }
    end
  end

  private

  def check_for_dir(dir)
    unless File.exists?(dir)
      puts "Error : Can't see '#{dir}' dir. Make sure you're in the correct directory and try again."
      exit
    end
  end

end