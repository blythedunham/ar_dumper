require File.join( File.dirname( __FILE__ ), 'test_helper' )

class ArDumperTest< TestCaseSuperClass

  fixtures :books, :topics

  #This allows us to easily create tests for all three output types
  def self.add_dump_test(options={})
    proc = options[:dump_options].delete(:procs) if options[:dump_options] && options[:dump_options][:procs]
    dump_options_str = (options[:dump_options]||{}).inspect

    if proc
      proc_str = proc.collect{|k,v| "#{k.inspect} => #{v}"}.join(',')
      dump_options_str.gsub!(/\}$/, ", :procs => { #{proc_str} } }")
      dump_options_str.gsub!(/^\{,/, '{')
    end

    %w(xml yml csv fixture).each do |export_type|
      extension = export_type == 'fixture' ? 'yml' : export_type
      new_method = %{
        def test_dumper_should_#{options[:name]||options[:expected_result]}_#{export_type}
          file_name = Book.dumper :#{export_type}, #{dump_options_str}
           result_file = assert_result_files(file_name, 
                          :format => :#{export_type},
                          :expected_results => '#{options[:expected_result]}.#{extension}',
                          :file_name_match => /ardumper\\.book\\.\\d+\\.\\d+\\.#{extension}/).first
        end
      }
  
      class_eval new_method, __FILE__, __LINE__
    end
  end

  def setup
    super
    FileUtils.rm_r ArDumper.dumper_file_path, :force => true
    FileUtils.mkdir_p ArDumper.dumper_file_path
  end

  def teardown
    super
    FileUtils.rm_r ArDumper.dumper_file_path
  end

  add_dump_test :name => 'dump', :expected_result => 'all_books'
  add_dump_test :name => 'dump_second_book', :expected_result => 'second_book',
                :dump_options => {:find => {:conditions => 'id = 2'}}
  

  add_dump_test :name => 'dump_only_option', :expected_result => 'only_title_and_author',
                :dump_options => {:only => [:title, :author_name]}


  add_dump_test :name => 'dump_except_option', :expected_result => 'except_title_and_author',
                :dump_options => {:except => [:title, :author_name]}

  
  add_dump_test :name => 'dump_only_and_method', :expected_result => 'topic_name',
                :dump_options => {:only => [:title, :author_name], :methods => [:topic_name]}

  add_dump_test(:name => 'dump_custom_proc', :expected_result => 'proc',
                 :dump_options => {
                        :find => {:conditions => 'id in (3,4)'},
                        :only => [:author_name],
                        :procs => {:topic_content => "Proc.new{|options|  options[:record].topic ? options[:record].topic.content : 'NO CONTENT' }"}})
                      

  protected

  def parse_csv( csv )
    parsed_csv = FasterCSV.parse( csv )
    headers = parsed_csv.first
    data = parsed_csv[1..-1]
    OpenStruct.new :headers=>headers, :data=>data, :size=>parsed_csv.size
  end

  def result_dir
    @result_dir ||= File.expand_path(File.join(File.dirname( __FILE__ ), 'data', 'results'))
  end

  def assert_result_files(file_name, options={})
    
    assert_equal(result_dir, File.expand_path(File.dirname(file_name)))
    assert file_name =~ options[:file_name_match], "File name #{file_name} did not match #{options[:file_name_match].inspect}" if options[:file_name_match]
    
    result_files = Dir.glob(File.join(ArDumper.dumper_file_path, '*'))

    assert_equal(options[:file_count]||1, result_files.length)

    if options[:expected_results]
      #remove timezone stamp
      expected_output = File.read(expected_results_file(options[:expected_results])).gsub( /-06(:?)00/, "-0" )
      actual_output = File.read(result_files.first).gsub(/-0\d(:?)00/, '-0')

      #fixture files are like yml but minus the --- (hash) at the top
      expected_output.gsub!(/^---\s\n/, "\n") if options[:format] == :fixture
      assert_equal(expected_output,actual_output)
    end

    result_files
  end

  def expected_results_file(file_name)
    @expected_results_dir ||= File.expand_path(File.join(File.dirname( __FILE__ ), 'data', 'expected_results'))
    File.join(@expected_results_dir, file_name)
  end
  
end