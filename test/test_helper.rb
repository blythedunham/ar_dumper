
dir = File.dirname(__FILE__)
require dir + '/run'
require dir +'/../init'

result_dir = File.join(dir, 'data', 'results')
FileUtils.mkdir_p(result_dir)
ArDumper.dumper_file_path = result_dir

puts "Using Rails version: #{ActiveRecord::VERSION::STRING}"

if ActiveRecord::VERSION::STRING < '2.3.1'

  TestCaseSuperClass = Test::Unit::TestCase
  class Test::Unit::TestCase #:nodoc:
    self.use_transactional_fixtures = true
    self.use_instantiated_fixtures = false

    def assert_queries(num = 1)
      $queries_executed = []
      yield
    ensure
      %w{ BEGIN COMMIT }.each { |x| $queries_executed.delete(x) }
      assert_equal num, $queries_executed.size, "#{$queries_executed.size} instead of #{num} queries were executed.#{$queries_executed.size == 0 ? '' : "\nQueries:\n#{$queries_executed.join("\n")}"}"
    end

  end

  Test::Unit::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
else



  TestCaseSuperClass = ActiveRecord::TestCase
  require 'active_record/test_case'
  class ActiveRecord::TestCase #:nodoc:
    include ActiveRecord::TestFixtures
    self.use_transactional_fixtures = true
    self.use_instantiated_fixtures = false
    self.fixtures :all
  end
  ActiveRecord::TestCase.fixture_path = File.dirname(__FILE__) + "/fixtures/"
end

#ActiveRecord::Base.connection.class.class_eval do
#  IGNORED_SQL = [/^PRAGMA/, /^SELECT currval/, /^SELECT CAST/, /^SELECT @@IDENTITY/, /^SELECT @@ROWCOUNT/, /^SAVEPOINT/, /^ROLLBACK TO SAVEPOINT/, /^RELEASE SAVEPOINT/, /SHOW FIELDS/]

#  def execute_with_query_record(sql, name = nil, &block)
#    $queries_executed ||= []
#    $queries_executed << sql unless IGNORED_SQL.any? { |r| sql =~ r }
#    execute_without_query_record(sql, name, &block)
#  end

#  alias_method_chain :execute, :query_record
#end

class TestCaseSuperClass
  def logger; ActiveRecord::Base.logger; end
  def self.logger; ActiveRecord::Base.logger; end
end
