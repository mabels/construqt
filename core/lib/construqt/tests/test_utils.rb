

require 'pry'

require 'test/unit'

require 'ruby-prof'

#RubyProf.start

#$LOAD_PATH.unshift(File.dirname(__FILE__))
#$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

CONSTRUQT_PATH=ENV['CONSTRUQT_PATH']||'./'
[
  "#{CONSTRUQT_PATH}/construqt/core/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/ubuntu/lib",
  "#{CONSTRUQT_PATH}/ipaddress/lib"
].each {|path| $LOAD_PATH.unshift(path) }
require 'construqt'

class UtilTest < Test::Unit::TestCase

    class Test1
      include Construqt::Util::Chainable
      #def initialize
      #  puts ">>>test instance=#{"%x"%self.object_id} class=#{"%x"%self.class.object_id}"
      #end
      attr_reader :sideeffect
      chainable_attr :bloed0
      chainable_attr :bloed1
      chainable_attr :test, 1, 2
      chainable_attr :testbool, false, true
      chainable_attr :testbool2, true, true
      chainable_attr :testside, 1, 2, lambda {|i| @sideeffect ||= 9; @sideeffect += 1 }
    end
    class Test2
      include Construqt::Util::Chainable
      #def initialize
      #  puts ">>>test instance=#{"%x"%self.object_id} class=#{"%x"%self.class.object_id}"
      #end
      attr_reader :sideeffect
      chainable_attr :bloed0
      chainable_attr :bloed1
      chainable_attr :test, 3, 4
      chainable_attr :testbool, true, false
      chainable_attr :testside, 3, 4, lambda {|i| @sideeffect ||= 5; @sideeffect += 1 }
    end

    def test_chainable
      3.times do |i|
        t = Test1.new
        #throw "chainable failed input_only" unless t.input_only? == true
        #throw "chainable failed output_only" unless t.output_only? == true

        #puts "#{i}=>#{t.testbool?} #{t.testbool2?}"
        throw "chainable failed test should 2 #{t.get_test.inspect}" if t.get_test != 2
        t.test
        throw "chainable failed this should be 1 " if t.get_test != 1
        t.test(3)
        throw "chainable failed" if t.get_test != 3

        throw "chainable failed test should 2 #{t.get_testside.inspect}" if t.get_testside != 2
        throw "chainable failed sideeffect should 1 nil #{t.sideeffect.inspect}" if !t.sideeffect.nil?
        t.testside
        throw "chainable failed this should be 1 " if t.get_testside != 1
        throw "chainable failed sideeffect should 2 nil #{t.sideeffect.inspect}" if t.sideeffect != 10
        t.testside(3)
        throw "chainable failed" if t.get_testside != 3
        throw "chainable failed sideeffect should 2 nil #{t.sideeffect.inspect}" if t.sideeffect != 11

        throw "chainable failed true" unless t.testbool? == true
        t.testbool
        throw "chainable failed false" unless t.testbool? == false
        t.testbool(4)
        throw "chainable failed 4" unless t.testbool? == 4
        t.testbool
        throw "chainable failed false" unless t.testbool? == false

        throw "chainable failed 2 true" unless t.testbool2? == true
        t.testbool2
        throw "chainable failed 2 false" unless t.testbool2? == true
        t.testbool2(4)
        throw "chainable failed 2 4" unless t.testbool2? == 4
        t.testbool2
        throw "chainable failed 2 false" unless t.testbool2? == true
      end
      a=[Test1.new,Test1.new,Test1.new]
      a[0].testbool(0)
      throw "chainable failed 0" unless a[0].testbool? == 0
      throw "chainable failed 1" unless a[1].testbool? == true
      a[2].testbool
      throw "chainable failed 2" unless a[2].testbool? == false

      throw "chainable failed 0" unless a[0].testbool? == 0
      throw "chainable failed 1" unless a[1].testbool? == true
      throw "chainable failed 2" unless a[2].testbool? == false
    end

  def assert_nets expect, result
    assert_equal expect, result.map{|i| i.to_string}
  end

    def test_NetworkAddressLookupTable
      ret = Construqt::Util.build_network_address_lookup_table([IPAddress.parse("1.2.3.4/25"), IPAddress.parse("1.2.4.4/24")])
      assert_equal([
        "1.2.3.0/25",
        "1.2.3.0/26",
        "1.2.3.0/27",
        "1.2.3.0/28",
        "1.2.3.0/29",
        "1.2.3.4/30",
        "1.2.3.4/31",
        "1.2.3.4/32",
        "1.2.4.0/24",
        "1.2.4.0/25",
        "1.2.4.0/26",
        "1.2.4.0/27",
        "1.2.4.0/28",
        "1.2.4.0/29",
        "1.2.4.4/30",
        "1.2.4.4/31",
        "1.2.4.4/32"
      ], ret.keys)
      assert_nets([
        "1.2.3.0/25",
        "1.2.3.0/26",
        "1.2.3.0/27",
        "1.2.3.0/28",
        "1.2.3.0/29",
        "1.2.3.4/30",
        "1.2.3.4/31",
        "1.2.3.4/32",
        "1.2.4.0/24",
        "1.2.4.0/25",
        "1.2.4.0/26",
        "1.2.4.0/27",
        "1.2.4.0/28",
        "1.2.4.0/29",
        "1.2.4.4/30",
        "1.2.4.4/31",
        "1.2.4.4/32"
      ], ret.values)

      ret = Construqt::Util.build_network_address_lookup_table([IPAddress.parse("1:2::3:4/125"), IPAddress.parse("1::2:4:4/124")])
      assert_equal([
        "1:2::3:0/125",
        "1:2::3:4/126",
        "1:2::3:4/127",
        "1:2::3:4/128",
        "1::2:4:0/124",
        "1::2:4:0/125",
        "1::2:4:4/126",
        "1::2:4:4/127",
        "1::2:4:4/128"
      ], ret.keys)
      assert_nets([
        "1:2::3:0/125",
        "1:2::3:4/126",
        "1:2::3:4/127",
        "1:2::3:4/128",
        "1::2:4:0/124",
        "1::2:4:0/125",
        "1::2:4:4/126",
        "1::2:4:4/127",
        "1::2:4:4/128"
      ], ret.values)

      ret = Construqt::Util.build_network_address_lookup_table([IPAddress.parse("1.2.3.4/25"), IPAddress.parse("1.2.4.4/24"),
                                             IPAddress.parse("1:2::3:4/125"), IPAddress.parse("1::2:4:4/124")])
      assert_equal([
        "1.2.3.0/25",
        "1.2.3.0/26",
        "1.2.3.0/27",
        "1.2.3.0/28",
        "1.2.3.0/29",
        "1.2.3.4/30",
        "1.2.3.4/31",
        "1.2.3.4/32",
        "1.2.4.0/24",
        "1.2.4.0/25",
        "1.2.4.0/26",
        "1.2.4.0/27",
        "1.2.4.0/28",
        "1.2.4.0/29",
        "1.2.4.4/30",
        "1.2.4.4/31",
        "1.2.4.4/32",
        "1:2::3:0/125",
        "1:2::3:4/126",
        "1:2::3:4/127",
        "1:2::3:4/128",
        "1::2:4:0/124",
        "1::2:4:0/125",
        "1::2:4:4/126",
        "1::2:4:4/127",
        "1::2:4:4/128"
      ], ret.keys)
      assert_nets([
        "1.2.3.0/25",
        "1.2.3.0/26",
        "1.2.3.0/27",
        "1.2.3.0/28",
        "1.2.3.0/29",
        "1.2.3.4/30",
        "1.2.3.4/31",
        "1.2.3.4/32",
        "1.2.4.0/24",
        "1.2.4.0/25",
        "1.2.4.0/26",
        "1.2.4.0/27",
        "1.2.4.0/28",
        "1.2.4.0/29",
        "1.2.4.4/30",
        "1.2.4.4/31",
        "1.2.4.4/32",
        "1:2::3:0/125",
        "1:2::3:4/126",
        "1:2::3:4/127",
        "1:2::3:4/128",
        "1::2:4:0/124",
        "1::2:4:0/125",
        "1::2:4:4/126",
        "1::2:4:4/127",
        "1::2:4:4/128"
      ], ret.values)
    end
end
