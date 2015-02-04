
require 'test/unit'

CONSTRUQT_PATH=ENV['CONSTRUQT_PATH']||'./'
["#{CONSTRUQT_PATH}/construqt/lib","#{CONSTRUQT_PATH}/ipaddress/lib"].each{|path| $LOAD_PATH.unshift(path) }
require 'construqt'


class TagsTest < Test::Unit::TestCase

  def test_parse_tags_empty
    assert_equal({}, Construqt::Tags.parse_tags(nil))
    assert_equal({}, Construqt::Tags.parse_tags(""))
  end

  def test_parse_tags_first_set
    assert_equal({'@' => ['DOOF']}, Construqt::Tags.parse_tags("@DOOF"))
    assert_equal({:first=>'MENO'}, Construqt::Tags.parse_tags("MENO"))
    assert_equal({:first=>'MENO', '@' => ['DOOF']}, Construqt::Tags.parse_tags("MENO@DOOF"))
  end

  def test_parse_tags
    assert_equal({
      "!"=>["BLA", "SOCK"],
      "#"=>["HEIN", "HUND"],
      "@"=>["BLOED", "DOOF", "HALLO"]
    }, Construqt::Tags.parse_tags('@DOOF#HEIN##@BLOED!SOCK@@HALLO!!BLA#HUND'))
    assert_equal({}, Construqt::Tags.parse_tags("@@!!##"))

    assert_equal({
      "!"=>["X", "Y"],
      "#"=>["A", "C"],
      "@"=>["HUND", "MENO"]
    }, Construqt::Tags.parse_tags("@MENO@HUND@MENO!X!Y!X#A#A#C!!@@##"))
    assert_equal({
      "!"=>["X", "Y"],
      "#"=>["A", "C"],
      "@"=>["HUND", "MENO"],
      :first => 'FIRST'
    }, Construqt::Tags.parse_tags("FIRST@MENO@HUND@MENO!X!Y!X#A#A#C!!@@##"))
  end
end
