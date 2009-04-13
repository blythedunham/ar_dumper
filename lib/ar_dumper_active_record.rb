# Refer to ArDumper for ActiveRecord extensions                   
class ActiveRecord::Base

  # Dump to csv string
  # Same as <tt>ActiveRecord::Base.dumper :csv, :target_type => :string</tt>
  def self.to_csv(options={})
    dump_to_string :csv, options
  end

  # Dump to yml
  # Same as <tt>ActiveRecord::Base.dumper :yml</tt>
  def self.dump_to_yaml(options={})
    dumper :yml, options
  end
 
  # Dump data
  # * +format+ - type of dump (<tt>:csv</tt>, <tt>:yml</tt>, <tt>:xml</tt>)
  # * +options+ - Dumper options. Refer to ArDumper
  def self.dumper(format, options={})
    ArDumper.new(self, options).dump(format)
  end
  
  # Dump to string.
  # Same as <tt> ActiveRecord::Base.dumper format, :target_type => :string</tt>
  def self.dumper_to_string(format, options={})
    dumper(format, options.update({:target_type => :string}))
  end
 
end


