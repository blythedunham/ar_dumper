#############################################################################
#
# Formats ActiveRecord data in chunks and dumps it to a file, temporary file, or string. Specify the page_size used to paginate
# records and flush files.
#
# ==Specify Output
# * <tt>:filename</tt> the name of the file to create. By default will create a file based on the timestamp.
# * <tt>:file_extension</tt> appends file extension unless one exists in file name
# * <tt>:only</tt> a list of the attributes to be included. By default, all column_names are used.
# * <tt>:except</tt> a list of the attributes to be excluded. By default, all column_names are used. This option is not available if +:only+ is used
# * <tt>:methods</tt> a list of the methods to be called on the object
# * <tt>:procs</tt> hash of header name to Proc object
#
# === Attributes (Only and Exclude)
# Specify which attributes to include and exclude
#   Book.dumper :yml, :only => [:author_name, :title]
#
#   Book.dump :csv, :except => [:topic_id]
#
# === Methods
# Use <tt>:methods</tt> to include methods on the record that are not column attributes
#   BigOle.dumper :csv, :methods => [:age, :favorite_food]
#   Output..
#   ..other attributes.., 25, doughnuts
#
# === Proc
# To call procs on the object(s) use <tt>:procs</tt> with a hash of name to value
# The dumper options hash are provided to the proc, and contains the current record <tt>options[:record]</tt> is provided
#
# ==== Proc Options Hash
# <tt>:record</tt> - the active record
# <tt>:result_set</tt> - the current result set
# <tt>:counter</tt> - the number of the record
# <tt>:page_num</tt> - the page number
# <tt>:target</tt> - the file/string target
#
#  topic_content_proc = Proc.new{|options|  options[:record].topic ? options[:record].topic.content : 'NO CONTENT' }
#  Book.dumper :procs => {:topic_content => topic_content_proc}})
#
#   <book>
#     # ... other attributes and methods ...
#     <topic-content>NO CONTENT</my_rating>
#   </book>
#
# == Finder Methods
# * <tt>:find</tt> a map of the finder options passed to find. For example, <tt> {:conditions => ['hairy = ?', 'of course'], :include => :rodents}</tt>
# * <tt>:records</tt> - the records to be dumped instead of using a find
#
# == Format Header
# * <tt>:header</tt> when a hash is specified, maps the field name to the header name. For example <tt>{:a => 'COL A', :b => 'COL B'}</tt> would print 'COL A', 'COL B'
#   when an array is specified uses this instead of the fields
#   when true or by default prints the fields
#   when false does not include a header
# * <tt>:text_format</tt> a string method such as <tt>:titleize</tt>, <tt>:dasherize</tt>, <tt>:underscore</tt> to format the on all the headers. If an attribute is <tt>:email_address</tt> and <tt>:titleize</tt> is chosen, then the Header value is "Email Address"
# * <tt>:root</tt> In xml, this is the name of the highest level list object. The plural of the class name is the default. For yml, this is the base name of the
#   the objects. Each record will be root_id. For example, contact_2348
#
# == Filename and Target
# <tt>:target_type</tt> The target_type for the data. Defaults to <tt>:file</tt>.
# * <tt>:string</tt> prints to string. Do not use with large data sets
# * <tt>:tmp_file</tt>. Use a temporary file that is destroyed when the process exists
# * <tt>:file</tt>. Use a standard file
# <tt>:filename</tt> basename of the file. Defaults to random time based string for non-temporary files
# <tt>:file_extension</tt> Extension (suffix) like .csv, .xml. Added only if the basename has no suffix.
# <tt>:file_extension</tt> is only available when <tt>:target_type_type => :file</tt>
# <tt>:file_path</tt> path or directory of the file. Defaults to dumper_file_path or temporary directories
#
# == Format specific options
# * <tt>:csv</tt> - any options to pass to csv parser. Example <tt> :csv => { :col_sep => "\t" }</tt>
# * <tt>:xml</tt> - any options to pass to xml parser. Example <tt> :xml => { :indent => 4 }    </tt>
#
# === Installation
#  script/plugin install git://github.com/blythedunham/ar_dumper.git
# === Developers
#  Blythe Dunham http://snowgiraffe.com
#
# === Homepage
# * Project Site: http://github.com/blythedunham/ar_dumper/tree/master
# * Rdoc: http://snowgiraffe.com/rdocs/ar_dumper
#
class ArDumper 

  #Page Size. Default 50
  cattr_accessor :dumper_page_size 
  @@dumper_page_size ||= 50

  # File Directory where dumps are stored
  # Defaults to temporary directory
  cattr_accessor :dumper_file_path
  @@dumper_file_path ||= ENV['TMPDIR']||ENV['TMP']||ENV['TEMP']||'.'

  # Basename of the dump files, defaulted to ardumper
  # Ex. ardumper.book.2348723947.23423.xml
  cattr_accessor :dumper_tmp_file_basename #default basename of temporary files
  @@dumper_tmp_file_basename ||= 'ardumper'

  # Specify the csv writer. Defaults to faster csv if available
  cattr_accessor :csv_writer

  attr_reader :fields
  attr_reader :klass
  attr_reader :options
  
  def initialize(klass, dump_options={})#:nodoc:
    @klass = klass
    @options = dump_options
    build_attribute_list
    
    unless options[:text_format].nil? || String.new.respond_to?(options[:text_format])
      raise ArDumperException.new("Invalid value for option :text_format #{options[:text_format]}")
    end
  end
  
  # build a list of attributes, methods and procs
  def build_attribute_list#:nodoc:
    if options[:only]
      options[:attributes] = Array(options[:only])
    else
      options[:attributes] = @klass.column_names - Array(options[:except]).collect { |e| e.to_s }
    end
      
    options[:attributes] = options[:attributes].collect{|attr| "#{attr}"}  
    options[:methods] = options[:methods].is_a?(Hash) ? options[:methods].values : Array(options[:methods])
    
    #if procs are specified as an array separate the headers(keys) from the procs(values)
    if options[:procs].is_a?(Hash)
      options[:proc_headers]= options[:procs].keys
      options[:procs]= options[:procs].values
    else
      options[:procs] = Array(options[:procs])
      options[:proc_headers]||= Array.new
      0.upto(options[:procs].size - options[:proc_headers].size - 1) {|idx| options[:proc_headers] << "proc_#{idx}" }
    end
    
  end

  # Dump to the appropriate format
  def dump(format)#:nodoc:

    case format.to_sym
      when :csv
        dump_to_csv
        
      when :xml
        dump_to_xml
        
      when :yaml, :fixture, :yml
        dump_to_fixture
        
      else
        raise ArDumperException.new("Unknown format #{format}. Please specify :csv, :xml, or :yml ")
    end
  end
  
  # Wrapper around the dump. The main dump functionality
  def dumper(file_extension=nil, header = nil, footer = nil, &block)#:nodoc:
    
    options[:counter] = -1
    begin
      #get the file parameters
      target = prepare_target(file_extension)
      target << header if header
      ArDumper.paginate_dump_records(@klass, @options) do |records, page_num|
      
        #save state on options to make it accessible by
        #class and procs
        options[:result_set] = records
        options[:page_num] = page_num
        
        records.each do |record|
          options[:record] = record
          yield record
        end
        
        #flush after each set
        target.flush if target.respond_to?(:flush)
      end
      target << footer if footer
      
    #final step close the options[:target]
    ensure
      target.close if target && target.respond_to?(:close)
    end

    options[:full_file_name]||target
  end
  
  #collect the record data into an array
  def dump_record(record)#:nodoc:
    record_values = @options[:attributes].inject([]){|values, attr| values << record["#{attr}"]; values }
    record_values = @options[:methods].inject(record_values) {|values, method| values << record.send(method); values }
    record_values = @options[:procs].inject(record_values){|values, proc| values << proc.call(options); values }
    record_values
  end
  

  #############################################################################
  # XML Dumper
  ############################################################################# 
  #
  # Dumps the data to an xml file
  # 
  # Using the ActiveRecord version of dumper so we CANNOT specify fields that are not attributes
  # 
  # In addition to options listed in +dumper+:
  # <tt>:xml</tt> - xml options for the xml_serializer. Includes <tt>:indent</tt>, <tt>:skip_instruct</tt>, <tt>:margin</tt>
  #
  # Note that <tt>:procs</tt> will use the dumper proc and pass the dumper options
  #   Book.dump :xml, :procs => {:topic_content => Proc.new { |options| options[:record].topic.content }}
  # To use xml proc, specify <tt> :xml => {:procs => array_of_procs}</tt>
  #   Book.dump :xml, :xml => {:procs => [Proc.new{|xml_options| xml_options[:builder].tag 'abc', 'def'}]}
  def dump_to_xml#:nodoc:
  
    #preserve the original skip instruct
    skip_instruct = @options[:xml] && @options[:xml][:skip_instruct].is_a?(TrueClass)

    self.options[:procs]||= []

    #use the fields if :only is not specified in the xml options
    xml_options = {
      :only => @options[:only],
      :except => @options[:except],
      :methods => @options[:methods]
    }
    
    xml_options.update(@options[:xml]) if @options[:xml]

    #do not instruct for each set
    xml_options[:skip_instruct] = true
    xml_options[:indent]||=2
    xml_options[:margin] = xml_options[:margin].to_i + 1
    
    #set the variable on the options
    options[:xml] = xml_options
    
    #builder for header and footer
    builder_options = {
      :margin => xml_options[:margin] - 1,
      :indent => xml_options[:indent]
    }
    
    options[:root] = (options[:root] || @klass.to_s.underscore.pluralize).to_s

    #use the builder to make sure we are indented properly
    builder = Builder::XmlMarkup.new(builder_options.clone)
    builder.instruct! unless skip_instruct
    builder << "<#{options[:root]}>\n"
    header = builder.target!
    
    #get the footer. Using the builder will make sure we are indented properly
    builder = Builder::XmlMarkup.new(builder_options)
    builder << "</#{options[:root]}>"
    footer = builder.target!

    dumper(:xml, header, footer) do |record|
      options[:target] << serialize_record_dump_xml(record, xml_options)
    end
  end

  # Serialize the xml data for the given record
  def serialize_record_dump_xml(record, xml_options)#:nodoc:

    serializer = ActiveRecord::XmlSerializer.new(record, xml_options.dup)
    xml = serializer.to_s do |builder|
      self.options[:procs].each_with_index do |proc, idx|
        serializer.add_tag_for_value(self.options[:proc_headers][idx].to_s,
                                     proc.call(self.options))
      end
    end
  end


  #############################################################################
  # Yaml/Fixture Dumper
  ############################################################################# 
  # dumps the data to a fixture file
  # In addition to options listed in +dumper+:
  # <tt>:root</tt> Basename of the record. Defaults to the class name so each record is named customer_1
  def dump_to_fixture#:nodoc:
    basename = @options[:root]||@klass.table_name.singularize
    header_list = build_header_list

    # doctor the yaml a bit to print the hash header at the top
    # instead of each record
    dumper(:yml, "---\s") do |record|
      record_data = Hash.new
      dump_record(record).each_with_index{|field, idx| record_data[header_list[idx].to_s] = field.to_s }
      options[:target] << {"#{basename}_#{record.id}" => record_data}.to_yaml.gsub(/^---\s\n/, "\n")
    end
  end
  
  
  
  #############################################################################
  # CSV DUMPER
  ############################################################################# 
  #
  # Dump csv data
  # 
  # * <tt>:csv</tt> - any options to pass to csv parser. 
  #   :col_sep Example + :csv => {:col_sep => "\t"} +
  #   :row_sep Row seperator
  # * <tt>:page_size</tt> - the page size to use. Defaults to dumper_page_size or 50
  def dump_to_csv#:nodoc:
    header = nil
    @options[:csv]||={}
    
    if !@options[:header].is_a?(FalseClass)
      header_list = build_header_list
      #print the header unless set to false
      header = write_csv_row(header_list)
    end
    
    dumper(:csv, header) do |record|
      options[:target] << write_csv_row(dump_record(record))
    end
  end
  
  # Write out the csv row using the selected csv writer
  def write_csv_row(row_data, header_list=[])#:nodoc: 
    if csv_writer == :faster
      ::FasterCSV::Row.new(header_list, row_data).to_csv(@options[:csv])
    else
      ::CSV.generate_line(row_data, @options[:csv][:col_sep], @options[:csv][:row_sep]) + (@options[:csv][:row_sep]||"\n")
    end
  end
  
  #Try to use the FasterCSV if it exists
  #otherwise use csv
  def csv_writer #:nodoc:
    unless @@csv_writer
      @@csv_writer = :faster
      begin 
        require 'faster_csv'#:nodoc:
        ::FasterCSV
      rescue Exception => exc
        @@csv_writer = :normal
      end
    end
    @@csv_writer
  end
  
  # Returns an array with the header names
  # This will be in the same order as the data returned by dump_record
  # attributes + methods + procs
  # 
  # <tt>:header</tt> The header defaults to the attributes and method names. When set
  #  to false no header is specified
  #   * +hash+ A map from attribute or method name to Header column name
  #   * +array+ A list in the same order that is used to display record data
  #   
  # <tt>:procs</tt> If a hash, then the keys are the names. If an array, then use proc_1, proc_2, etc
  # <tt>:text_format</tt> Format names with a text format such as +:titlieze+, +:dasherize+, +:underscore+
  def build_header_list#:nodoc:
  
    header_options = options[:header]
    columns = @options[:attributes] + @options[:methods]
    header_names = 
      if header_options.is_a?(Hash)
        header_options.symbolize_keys!
        
        #Get the header for each attribute and method
        columns.collect{|field|(header_options[field.to_sym]||field).to_s}
        
      #ordered by attributes, methods, then procs
      elsif header_options.is_a?(Array)
        header_names = header_options
        header_names.concat(columns[header_options.length..-1]) if header_names.length < columns.length
        
      #default to column names 
      else
        columns
      end
    
    #add process names
    header_names.concat(options[:proc_headers])
    
    #format names with a text format such as titlieze, dasherize, underscore
    header_names.collect!{|n| n.to_s.send(options[:text_format])} if options[:text_format]
    
    header_names
  end
    
  

  
    
  # Create the options[:target](file) based on these options. The options[:target] must respond to <<
  # Current options[:target]s are :string, :file, :tempfile
  #
  # <tt> :target_type</tt> The options[:target] for the data. Defaults to +:file+
  #   * :string prints to string. Do not use with large data sets
  #   * :tmp_file. Use a temporary file that is destroyed when the process exists
  #   * :file. Use a standard file
  # <tt> :filename </tt> basename of the file. Defaults to random time based string for non-temporary files
  # <tt> :file_extension </tt> Extension (suffix) like .csv, .xml. Added only if the basename has no suffix. 
  #  :file_extension is only available when +:target_type_type => :file+
  # <tt> :file_path </tt> path or directory of the file. Defaults to dumper_file_path or temporary directories
 
  def prepare_target(file_extension = nil)#:nodoc:
    
    options[:target] = case options[:target_type]
      #to string option dumps to a string instead of a file
      when :string
        String.new
        
      #use a temporary file
      #open a temporary file with the basename specified by filename
      #defaults to the value of one of the environment variables TMPDIR, TMP, or TEMP
      when :tmp_file

        Tempfile.open(options[:filename]||(@@dumper_tmp_file_basename+@klass.name.downcase), 
                      options[:file_path]||@@dumper_file_path)
                      
      #default to a real file                
      else
        extension = options[:file_extension]||file_extension
        mode = options[:append_to_file].is_a?(TrueClass)? 'a' : 'w'
        filename = options[:filename]||"#{@@dumper_tmp_file_basename}.#{@klass.name.downcase}.#{Time.now.to_f.to_s}.#{extension}"
        
        #append an extension unless one already exists
        filename += ".#{extension}" if extension && !filename =~ /\.\w*$/
        
        #get the file path if the filename does not contain one
        if File.basename(filename) == filename
          path = options[:file_path]||@@dumper_file_path 
          filename = File.join(path, filename) unless path.blank?
        end

        
        File.open(filename, mode)
     end
     
    options[:full_file_name] = options[:target].path if options[:target].respond_to?(:path)
    options[:target]
  end
  
  
    
  #############################################################################
  # Pagination Helpers (Support before 2.3.2)
  ############################################################################# 
  #
  #
  # Quick and dirty paginate to loop thru the records page by page
  # Options are:
  # * <tt>:find</tt> - a map of the finder options passed to find. For example, + {:conditions => ['hairy = ?', 'of course'], :include => :rodents} +
  # * <tt>:page_size</tt> - the page size to use. Defaults to dumper_page_size or 50. Set to false to disable pagination
  # * <tt>:records</tt> - the records to be dumped instead of using a find
  def self.paginate_dump_records(klass, options={}, &block)#:nodoc:
    finder_options = (options[:find]||{}).clone
    
    if options[:records]
      yield options[:records], 0
      return
    #pagination is not needed when :page_size => false
    elsif options[:page_size].is_a?(FalseClass)
      yield klass.find(:all, finder_options), 0
      return
    end
    
    options[:page_size]||= dumper_page_size
    
    #limit becomes the maximum amount of records to pull
    max_records = finder_options[:limit]
    page_num = 0
    finder_options[:limit] = compute_page_size(max_records, page_num, options[:page_size])
    records = []
    while (finder_options[:limit] > 0 && (page_num == 0 || records.length == options[:page_size]))      
      records = klass.find :all, finder_options.update(:offset => page_num * options[:page_size])
      
      yield records, page_num
      page_num = page_num + 1
      
      #calculate the limit if an original limit (max_records) was set
      finder_options[:limit] = compute_page_size(max_records, page_num, options[:page_size])
    end
  end
  
  def self.compute_page_size(max_records, page_num, page_size)#:nodoc:
    max_records ? [(max_records - (page_num * page_size)), page_size].min : page_size
  end
  
  # Quick and dirty paginate to loop thru each page
  # Options are:
  # * <tt>:find</tt> - a map of the finder options passed to find. For example, + {:conditions => ['hairy = ?', 'of course'], :include => :rodents} +
  # * <tt>:page_size</tt> - the page size to use. Defaults to dumper_page_size or 50. Set to false to disable pagination
  def self.paginate_each_record(klass, options={}, &block)#:nodoc:
    counter = -1
    paginate_dump_records(klass, options) do |records, page_num|
      records.each do |record| 
        yield record, (counter +=1)
      end
    end
  end                        
end

class ArDumperException < Exception#:nodoc:
end






