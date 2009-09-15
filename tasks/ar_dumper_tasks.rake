VALID_DUMPER_OPTIONS = [:filename, :file_extension, :target_type,
      :only, :except, :methods, :procs, :find, :records,
      :header, :text_format, :root]

namespace :dumper do
  desc "Dumps entire model in FORMAT. rake dumper FORMAT=csv MODEL=User FILEPATH=fixtures FILENAME = users.yml"
  task :dump => :environment do
    raise "Please specify MODEL=class" unless ENV['MODEL']
    raise "Please specify FORMAT=format (csv, yml, xml, fixtures)" unless ENV['FORMAT']


    options = (VALID_DUMPER_OPTIONS - [:find]).inject({}) do |map, option|
      map[option] = ENV[option.to_s.upcase] if ENV[option.to_s.upcase]
      map
    end

    #accept with and without hyphen
    options[:filename] ||= ENV['FILENAME']
    options[:file_path]||= ENV['FILEPATH']

    options[:find] = eval(ENV['FIND']) if ENV['FIND']
    options[:find] ||= { :conditions => ENV['FIND_CONDITIONS'] } if ENV['FIND_CONDITIONS']

    #file extension is not always properly added
    options[:file_extension]||= ENV['FORMAT'] == 'fixture' ? 'yml' : ENV['FORMAT']

    model_klass = ENV['MODEL'].classify.constantize
    format = ENV['FORMAT']

    puts model_klass.dumper ENV['FORMAT'].to_s.downcase, options
  end

  [:yml, :fixture, :xml, :csv].each do |method|
    class_eval <<-END_TASK
    desc "Dumps entire model to #{method}"
    task :#{method} do
      ENV['FORMAT'] = '#{method}'
      Rake::Task['dumper:dump'].invoke
    end
  END_TASK
  end

end
