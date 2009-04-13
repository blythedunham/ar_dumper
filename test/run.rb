dir = File.dirname( __FILE__ )

require 'rubygems'
if version=ENV["AR_VERSION"]
  gem 'activerecord', version
  gem 'actionpack', version
else
  gem 'activerecord'
  gem 'actionpack'
end
require 'active_record'
require 'active_record/version'
require 'actionpack'
require 'action_controller'
require 'action_controller/test_case'


ActiveRecord::Base.logger = Logger.new("debug.log")

config = ActiveRecord::Base.configurations['test'] = {
  :adapter  => "mysql",
  :username => "root",
  :encoding => "utf8",
  :host => '127.0.0.1',
  :database => 'dumper_test' }

ActiveRecord::Base.establish_connection( config )

require File.join(dir, '../db/migrate/generic_schema')

require 'mocha'
require 'test/unit'
require 'fileutils'
require 'active_record/fixtures'


Dir.glob(File.join(dir, 'models', '*.rb')) {|f| require f }

