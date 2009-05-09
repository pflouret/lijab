require 'rubygems'

require 'date'
require 'rake'
require 'rake/clean'
require 'rake/gempackagetask'

spec = Gem::Specification.new do |s|

   s.name = 'lijab'
   s.version = '0.1.1'
   s.date = Time.now.to_s
   s.required_ruby_version = ">=1.8.0"

   s.summary = "Extensible line oriented jabber client"

   s.executables = ['lijab']
   s.files = Dir.glob("ext/*.{rb,c}") +
             Dir.glob("lib/**/*.rb")

   s.extensions << 'ext/extconf.rb'
   s.require_path = 'lib'

   s.add_dependency "file-tail"
   s.add_dependency "term-ansicolor"
   s.add_dependency "xmpp4r"

   s.author = "Pablo Flouret"
   s.email = "quuxbaz@gmail.com"
   s.homepage = "http://github.com/palbo/lijab"

end

VERSION_FILE_CONTENTS = %Q{
module Lijab
   VERSION = '%s'
end
}

CLEAN.include("pkg")

def write_version_file(v)
   File.open("lib/lijab/version.rb", "w") do |f|
      f.puts(VERSION_FILE_CONTENTS % v)
   end
end

desc "Clean and repackage dev version"
task :default => [ :clean, :versiondev, :repackage ]

desc "Generate version file"
task :version do
   write_version_file(spec.version.to_s)
end

desc "Generate git aware version file"
task :versiondev do
   if File.directory?('.git')
      commit = `git log -1 --pretty=format:%h`.chomp
      branch = `git branch`.split("\n").grep(/^\*/).first
      branch.chomp! if branch
      branch = (branch.gsub(/^\* /, '') if branch && !branch.empty? && branch != "* master") || nil
      additional = "#{'-'+branch if branch}#{'-'+commit if commit}"
      additional = "-git-#{Date.today.strftime('%Y%m%d')}#{additional}" if additional
   end
   write_version_file("#{spec.version.to_s}#{additional}")
end

desc "Create .gemspec file"
task :gemspec do
   filename = "#{spec.name}.gemspec"
   File.open(filename, "w") do |f|
      f.puts spec.to_ruby
   end
end

desc "Prepare for release"
task :release => [:clean, :version, :gemspec, :repackage] do
   require './lib/lijab/version.rb'
   if spec.version.to_s == Lijab::VERSION
      STDERR.puts "you forgot to bump the version!"
   end
end

desc "Install the gem locally"
task :install => [:clean, :versiondev, :repackage] do
   system("sudo gem install pkg/lijab-#{spec.version}.gem")
end

desc "Reinstall the gem"
task :reinstall => [:clean, :versiondev, :repackage] do
   system("sudo gem uninstall lijab")
   Rake::Task[:install].invoke
end

Rake::GemPackageTask.new(spec) do |pkg|
   pkg.need_tar_gz = true
   #pkg.need_zip = true
end

