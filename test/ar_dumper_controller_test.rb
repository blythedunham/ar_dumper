require File.join( File.dirname( __FILE__ ), 'test_helper' )

class ArDumperControllerTest < TestCaseSuperClass
  fixtures :books

  def test_dumper_should_dump_csv
    assert(true)
  end

end