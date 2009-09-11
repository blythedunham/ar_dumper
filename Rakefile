
require 'rubygems'
require 'rake/gempackagetask'
require 'rake/testtask'
require 'rake/rdoctask'
 
desc 'Default: run unit tests.'
task :default => [:clean, :test]

desc 'Clean up files.'
task :clean do |t|
  FileUtils.rm_rf "doc"
  FileUtils.rm_rf "tmp"
  FileUtils.rm_rf "pkg"
  FileUtils.rm "debug.log" rescue nil
  FileUtils.rm "test/debug.log" rescue nil
  Dir.glob("ar_dumper-*.gem").each{|f| FileUtils.rm f }
end

include_file_globs = ["README*",
                      "LICENSE",
                      "Rakefile",
                      "init.rb",
                      "{db,lib,test}/**/*"]
                       
spec = Gem::Specification.new do |s|
    s.name = "ar_dumper"
    s.version = "1.2.0.0"
    s.author = "Blythe Dunham"
    s.email = "blythe@snowgiraffe.com"
    s.homepage = "http://github.com/blythedunham/ar_dumper"
    s.platform = Gem::Platform::RUBY
    s.summary = "Extends ActiveRecord to export volume records to a file, string, or temp file in csv, yaml, or xml formats"
    s.files = FileList[include_file_globs].to_a
    s.require_path = "lib"
    s.test_files = FileList["test/**/*_test.rb"].to_a
    s.rubyforge_project = "ar_dumper"
    s.has_rdoc = true
    s.extra_rdoc_files = FileList["README*"].to_a
    s.rdoc_options << '--line-numbers' << '--inline-source'
end

 desc "Print a list of the files to be put into the gem"
 task :manifest => :clean do
   spec.files.each do |file|
     puts file
   end
 end

 desc "Generate a gemspec file for GitHub"
 task :gemspec => :clean do
   File.open("#{spec.name}.gemspec", 'w') do |f|
     f.write spec.to_ruby
   end
 end

 desc "Build the gem into the current directory"
 task :gem => :gemspec do
   `gem build #{spec.name}.gemspec`
 end
 
 
Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
end
 
desc "Run tests"
Rake::TestTask.new("test") { |t|
  t.pattern = 'test/*_test.rb'
  t.verbose = true
  t.warning = true
}
 
task :default => "pkg/#{spec.name}-#{spec.version}.gem" do
    puts "generated latest version"
end