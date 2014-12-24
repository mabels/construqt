require "test/unit"
require_relative "../parser.rb"

module Construqt
  module SwitchDelta
    class TestSwitchConfigParser < Test::Unit::TestCase

      def test_resolvePortDefinition
        assert_equal(["1","2"], SwitchConfigParser.new().resolvePortDefinition("1-2"))
        assert_equal(["1","2","3"], SwitchConfigParser.new().resolvePortDefinition("1-3"))
        assert_equal(["eth0/0/1","eth0/0/2","eth0/0/3","eth0/0/4",
                      "eth0/0/5","eth0/0/6","eth0/0/7","eth0/0/8","eth0/0/9",
                      "eth0/0/10","eth0/0/11"], SwitchConfigParser.new().resolvePortDefinition("eth0/0/1-eth0/0/11"))
        assert_equal(["Trk1","Trk2","Trk3","Trk4","Trk5",
                      "Trk6","Trk7","Trk8","Trk9","Trk10","Trk11","Trk12",
                      "Trk13"], SwitchConfigParser.new().resolvePortDefinition("Trk1-Trk13"))
      end

    end
  end
end
