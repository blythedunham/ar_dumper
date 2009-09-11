# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ar_dumper}
  s.version = "1.2.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Blythe Dunham"]
  s.date = %q{2009-09-10}
  s.email = %q{blythe@snowgiraffe.com}
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["README.rdoc", "LICENSE", "Rakefile", "init.rb", "db/migrate", "db/migrate/generic_schema.rb", "lib/ar_dumper.rb", "lib/ar_dumper_active_record.rb", "lib/ar_dumper_controller.rb", "lib/xml_serializer_dumper_support.rb", "test/ar_dumper_controller_test.rb", "test/ar_dumper_test.rb", "test/data", "test/data/expected_results", "test/data/expected_results/all_books.csv", "test/data/expected_results/all_books.xml", "test/data/expected_results/all_books.yml", "test/data/expected_results/except_title_and_author.csv", "test/data/expected_results/except_title_and_author.xml", "test/data/expected_results/except_title_and_author.yml", "test/data/expected_results/only_title_and_author.csv", "test/data/expected_results/only_title_and_author.xml", "test/data/expected_results/only_title_and_author.yml", "test/data/expected_results/proc.csv", "test/data/expected_results/proc.xml", "test/data/expected_results/proc.yml", "test/data/expected_results/second_book.csv", "test/data/expected_results/second_book.xml", "test/data/expected_results/second_book.yml", "test/data/expected_results/topic_name.csv", "test/data/expected_results/topic_name.xml", "test/data/expected_results/topic_name.yml", "test/fixtures", "test/fixtures/books.yml", "test/fixtures/topics.yml", "test/models", "test/models/book.rb", "test/models/topic.rb", "test/run.rb", "test/test_helper.rb"]
  s.homepage = %q{http://github.com/blythedunham/ar_dumper}
  s.rdoc_options = ["--line-numbers", "--inline-source"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{ar_dumper}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Extends ActiveRecord to export volume records to a file, string, or temp file in csv, yaml, or xml formats}
  s.test_files = ["test/ar_dumper_controller_test.rb", "test/ar_dumper_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
