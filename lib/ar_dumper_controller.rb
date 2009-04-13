class ActionController::Base

  #Change to :file to use regular files
  cattr_accessor :dumper_target
  @@dumper_target = :tmp_file
  
  
  # send a dumped file
  # Options are:
  # <tt>klass</tt> - the active record to use. Animal or Contact or Author or Tumama
  # <tt>send_options</tt> send_options include send_file options such as <tt>:type</tt> and <tt>:disposition</tt>
  # <tt>dump_options</tt> options to send to the dumper. These options are in <tt>ArDumper.dump_to_csv</tt>
  # * <tt>:find</tt> - a map of the finder options passed to find. For example, <tt>{:conditions => ['features.hair = ?', 'blonde'], :include => :features}</tt>
  # * <tt>:header</tt> - when a hash is specified, maps the field name to the header name. For example <tt>{:a => 'COL A', :b => 'COL B'}</tt> would print 'COL A', 'COL B'
  #                      when an array is specified uses this instead of the fields
  #                      when true or by default prints the fields
  #                      when false does not include a header
  # * <tt>:csv</tt> - any options to pass to csv parser. Example <tt> :csv => { :col_sep => "\t" }</tt>
  # * <tt>:xml</tt> - any options to pass to xml parser. Example <tt> :xml => { :indent => 4 }    </tt>
  # * <tt>:page_size</tt> - the page size to use. Defaults to dumper_page_size or 50
  def send_file_dump(format, klass, send_options={}, dump_options={})

    #use the base name of the dump file name if specified
    send_options[:filename] ||= File.basename(dump_options[:filename]) if dump_options[:filename]
    
    #never delete the file
    dump_options[:delete_file] = false
    
    #use temporary files unless otherwise specified
    dump_options[:target_type]||= @@dumper_target
        
    #send_options[:type] = 'application/xml; charset=utf-8;'
    if send_options[:type].nil? && send_options[:disposition] == 'inline'
      send_options[:type] =
        case format.to_sym
          when :xml then 'application/xml; charset=utf-8;'
          when :csv then 'application/csv; charset=utf-8;'
          when :yml then 'text/html; charset=utf-8;'
        end

    end

    target = klass.dumper(format, dump_options)
    
    if dump_options[:target_type] == :string
      send_data(target, send_options)
    else
      send_file(target, send_options)
    end
  end
 
end