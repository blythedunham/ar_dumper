# Add support to ActiveRecord::XmlSerializer to have value based tags
class ActiveRecord::XmlSerializer
  #Add ability to set margin with options to serializer
  def builder_with_margin#:nodoc:
    @builder ||= begin
      options[:indent] ||= 2
      options[:margin] ||= 0
      builder = options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent], :margin => options[:margin])

      unless options[:skip_instruct]
        builder.instruct!
        options[:skip_instruct] = true
      end

      builder
    end
  end

  alias_method_chain :builder, :margin

  # Adds a tag based on the name and value and the serializer options
  # Decorations for the tag are derived from the value type
  #
  #  add_tag_for_value('my_tag', "some data")
  #  # XML: <my-tag>some data</my-tag>
  def add_tag_for_value(name, value)
    add_tag(ValueAttribute.new(name, @record, value))
  end
  

  # An attribute where the type and value are based on the
  # values when created
  class ValueAttribute < Attribute
    def initialize(name, record, value)
      @value = value
      super(name, record)
    end

    def compute_value#:nodoc:
      @value
    end

    def compute_type#:nodoc:
      Hash::XML_TYPE_NAMES[@value.class.name] || :string
    end
  end
end

#ActiveRecord::XmlSerializer.send :include, XmlSerializerDumperSupport unless ActiveRecord.respond_to?(:add_procs_with_record)