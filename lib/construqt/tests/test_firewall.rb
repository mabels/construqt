

require 'test/unit'

#$LOAD_PATH.unshift(File.dirname(__FILE__))
#$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

CONSTRUQT_PATH=ENV['CONSTRUQT_PATH']||'.'
["#{CONSTRUQT_PATH}/construqt/lib","#{CONSTRUQT_PATH}/ipaddress/lib"].each{|path| $LOAD_PATH.unshift(path) }
require 'construqt'

network = Construqt::Networks.add('Construqt-Test-Network')
REGION = Construqt::Regions.add("Construqt-Test-Region", network)

REGION.network.addresses.tag("TEST")
  .add_ip("1.1.1.1/24#FIRST_NET_1_TAG#TESTIPV4")
  .add_ip("1.1.1.2/24#FIRST_NET_2_TAG#TESTIPV4")
  .add_ip("1::1:1:1/124#FIRST_NET_1_TAG#TESTIPV6")
  .add_ip("1::1:1:2/124#FIRST_NET_2_TAG#TESTIPV6")
REGION.network.addresses.tag("TEST")
  .add_ip("2.2.2.2/24#SECOND_NET_1_TAG")
  .add_ip("2.2.2.3/24#SECOND_NET_2_TAG")
  .add_ip("2::2:2:2/124#SECOND_NET_1_TAG")
  .add_ip("2::2:2:3/124#SECOND_NET_2_TAG")


REGION.hosts.add("Construqt-Host", "flavour" => "ubuntu") do |cq|
  cq.configip = cq.id ||= Construqt::HostId.create do |my|
    my.interfaces << TEST_IF = REGION.interfaces.add_device(cq, "v995", "mtu" => 1500,
                                                            'address' => REGION.network.addresses
      .add_ip("5.5.5.5/24")
      .add_ip("5.5.5.6/24")
      .add_ip("5.5.6.5/24")
      .add_ip("5.5.6.6/24")
      .add_route("11.11.11.0/24", "5.5.6.7")
      .add_route("12.12.12.0/24", "5.5.6.7")
      .add_ip("5::5:5:5/124")
      .add_ip("5::5:5:6/124")
      .add_ip("5::5:6:5/124")
      .add_ip("5::5:6:6/124")
      .add_route("11::11:11:0/124", "5::5:6:7")
      .add_route("12::12:12:0/124", "5::5:6:7"))
  end
end

class FirewallTest < Test::Unit::TestCase

  #  def helper_test_metods
  #    from_net
  #    to_net
  #    from_host
  #    to_host
  #    from_me
  #    to_me
  #  end

  def assert_nets expect, result
    assert_equal expect, result.map{|i| i.to_string}
  end

  def assert_array expect, result
    if expect.size != result.size
      assert_equal expect, result
    else
      expect.each_with_index do |e, idx|
        assert_equal e, result[idx]
      end
    end
  end

  def create_rule
    rule = Construqt::Firewalls::Firewall::Forward::ForwardEntry.new(nil).action("<action>")
    rule.attached_interface = TEST_IF
    rule
  end

  class TestToFromFactory
    def initialize(name = "DEFAULT")
      @name = name
      @rows = []
    end

    class Row
      def table(name)
        @table = name
        self
      end

      def get_table
        @table || "DEFAULT"
      end

      def row(line)
        @row = line
        self
      end

      def get_row
        @row
      end
    end

    def rows
      @rows.map{|i| ["{#{i.get_table.strip}}","#{i.get_row.strip}"].join(" ") }
    end

    def create
      row = Row.new.table(@name)
      @rows << row
      row
    end
  end

  class TestSection
    attr_reader :input, :output, :forward
    def initialize
      @input = TestToFromFactory.new("INPUT")
      @output = TestToFromFactory.new("OUTPUT")
      @forward = TestToFromFactory.new("FORWARD")
    end

    def rows
      @input.rows + @output.rows + @forward.rows
    end
  end

  class TestWriter
    attr_reader :jump_destinations
    def initialize
      @jump_destinations = {}
    end

    def ipv4
      @ipv4 ||= TestSection.new
    end

    def ipv6
      @ipv6 ||= TestSection.new
    end
  end

  def create_to_from(rule)
    Construqt::Flavour::Ubuntu::Firewall::ToFrom.new("testifname", rule, TestSection.new, TestToFromFactory.new)
  end

  def test_from_list_v4_from_net_iface_network
    rule = create_rule
    family = Construqt::Addresses::IPV4
    assert_nets [], rule.from_list(family)
    rule.from_net
    assert_nets ["5.5.5.0/24", "5.5.6.0/24"], rule.from_list(family)
    rule.from_net.include_routes
    assert_nets ["5.5.5.0/24", "5.5.6.0/24", "11.11.11.0/24", "12.12.12.0/24"], rule.from_list(family)
  end

  def test_from_list_v4_from_net_parameter
    rule = create_rule
    family = Construqt::Addresses::IPV4
    assert_nets [], rule.from_list(family)
    rule.from_net("UNKNOWN_TAG")
    assert_nets [], rule.from_list(family)
    rule.from_net("FIRST_NET_1_TAG#FIRST_NET_2_TAG")
    assert_nets ["1.1.1.0/24"], rule.from_list(family)
    rule.from_net("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG")
    assert_nets ["1.1.1.0/24", "2.2.2.0/24"], rule.from_list(family)
    rule.from_net("@8.8.8.8/24")
    assert_nets ["8.8.8.0/24"], rule.from_list(family)
    rule.from_net("@8.8.8.8/24@8.8.4.4/24")
    assert_nets ["8.8.4.0/24","8.8.8.0/24"], rule.from_list(family)
    rule.from_net("@www.slashdot.org")
    assert_nets ["216.34.181.48/32"], rule.from_list(family)
    rule.from_net("@www.slashdot.org@heise.de")
    assert_nets ["193.99.144.80/32", "216.34.181.48/32"], rule.from_list(family)
    rule.from_net("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG@www.slashdot.org@heise.de@8.8.8.8/24@8.8.4.4/24")
    assert_nets ["1.1.1.0/24", "2.2.2.0/24", "8.8.4.0/24", "8.8.8.0/24", "193.99.144.80/32", "216.34.181.48/32"], rule.from_list(family)
    rule.from_net("TEST")
    assert_nets ["1.1.1.0/24", "2.2.2.0/24"], rule.from_list(family)
  end

  def test_from_list_v4_from_host_iface_network
    rule = create_rule
    family = Construqt::Addresses::IPV4
    assert_nets [], rule.from_list(family)
    rule.from_host
    assert_nets ["5.5.5.5/32", "5.5.5.6/32", "5.5.6.5/32", "5.5.6.6/32"], rule.from_list(family)
    rule.from_host.include_routes
    assert_nets ["5.5.5.5/32",
                 "5.5.5.6/32",
                 "5.5.6.5/32",
                 "5.5.6.6/32",
                 "11.11.11.0/24",
                 "12.12.12.0/24"], rule.from_list(family)
  end

  def test_from_list_v4_from_host_parameter
    rule = create_rule
    family = Construqt::Addresses::IPV4
    assert_nets [], rule.from_list(family)
    rule.from_host("UNKNOWN_TAG")
    assert_nets [], rule.from_list(family)
    rule.from_host("FIRST_NET_1_TAG#FIRST_NET_2_TAG")
    assert_nets ["1.1.1.1/32", "1.1.1.2/32"], rule.from_list(family)
    rule.from_host("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG")
    assert_nets ["1.1.1.1/32", "1.1.1.2/32", "2.2.2.2/31"], rule.from_list(family)
    rule.from_host("@8.8.8.8/24")
    assert_nets ["8.8.8.8/32"], rule.from_list(family)
    rule.from_host("@8.8.8.8/24@8.8.4.4/24")
    assert_nets ["8.8.4.4/32","8.8.8.8/32"], rule.from_list(family)
    rule.from_host("@8.8.8.8@8.8.4.4")
    assert_nets ["8.8.4.4/32","8.8.8.8/32"], rule.from_list(family)
    rule.from_host("@www.slashdot.org")
    assert_nets ["216.34.181.48/32"], rule.from_list(family)
    rule.from_host("@www.slashdot.org@heise.de")
    assert_nets ["193.99.144.80/32", "216.34.181.48/32"], rule.from_list(family)
    rule.from_host("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG@www.slashdot.org@heise.de@8.8.8.8/24@8.8.4.4/24")
    assert_nets ["1.1.1.1/32", "1.1.1.2/32", "2.2.2.2/31", "8.8.4.4/32", "8.8.8.8/32", "193.99.144.80/32", "216.34.181.48/32"], rule.from_list(family)
    rule.from_host("TEST")
    assert_nets ["1.1.1.1/32", "1.1.1.2/32", "2.2.2.2/31"], rule.from_list(family)
  end

  def test_from_list_v6_from_net_iface_network
    rule = create_rule
    family = Construqt::Addresses::IPV6
    assert_nets [], rule.from_list(family)
    rule.from_net
    assert_nets ["5::5:5:0/124", "5::5:6:0/124"], rule.from_list(family)
    rule.from_net.include_routes
    assert_nets ["5::5:5:0/124", "5::5:6:0/124", "11::11:11:0/124", "12::12:12:0/124"], rule.from_list(family)
  end

  def test_from_list_v6_from_net_parameter
    rule = create_rule
    family = Construqt::Addresses::IPV6
    assert_nets [], rule.from_list(family)
    rule.from_net("UNKNOWN_TAG")
    assert_nets [], rule.from_list(family)
    rule.from_net("FIRST_NET_1_TAG#FIRST_NET_2_TAG")
    assert_nets ["1::1:1:0/124"], rule.from_list(family)
    rule.from_net("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG")
    assert_nets ["1::1:1:0/124", "2::2:2:0/124"], rule.from_list(family)
    rule.from_net("@8::8:8:8/124")
    assert_nets ["8::8:8:0/124"], rule.from_list(family)
    rule.from_net("@8::8:8:8/124@8::8:4:4/124")
    assert_nets ["8::8:4:0/124","8::8:8:0/124"], rule.from_list(family)
    rule.from_net("@google-public-dns-a.google.com")
    assert_nets ["2001:4860:4860::8888/128"], rule.from_list(family)
    rule.from_net("@google-public-dns-a.google.com@google-public-dns-b.google.com")
    assert_nets ["2001:4860:4860::8844/128", "2001:4860:4860::8888/128"], rule.from_list(family)
    rule.from_net("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG@google-public-dns-a.google.com@google-public-dns-b.google.com@8::8:8:8/124@8::8:4:4/124")
    assert_nets ["1::1:1:0/124", "2::2:2:0/124", "8::8:4:0/124", "8::8:8:0/124", "2001:4860:4860::8844/128", "2001:4860:4860::8888/128"], rule.from_list(family)
    rule.from_net("TEST")
    assert_nets ["1::1:1:0/124", "2::2:2:0/124"], rule.from_list(family)
  end

  def test_from_list_v6_from_host_iface_network
    rule = create_rule
    family = Construqt::Addresses::IPV6
    assert_nets [], rule.from_list(family)
    rule.from_host
    assert_nets ["5::5:5:5/128", "5::5:5:6/128", "5::5:6:5/128", "5::5:6:6/128"], rule.from_list(family)
    rule.from_host.include_routes
    assert_nets ["5::5:5:5/128",
                 "5::5:5:6/128",
                 "5::5:6:5/128",
                 "5::5:6:6/128",
                 "11::11:11:0/124",
                 "12::12:12:0/124"], rule.from_list(family)
  end

  def test_from_list_v6_from_host_parameter
    rule = create_rule
    family = Construqt::Addresses::IPV6
    assert_nets [], rule.from_list(family)
    rule.from_host("UNKNOWN_TAG")
    assert_nets [], rule.from_list(family)
    rule.from_host("FIRST_NET_1_TAG#FIRST_NET_2_TAG")
    assert_nets ["1::1:1:1/128", "1::1:1:2/128"], rule.from_list(family)
    rule.from_host("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG")
    assert_nets ["1::1:1:1/128", "1::1:1:2/128", "2::2:2:2/127"], rule.from_list(family)
    rule.from_host("@8::8:8:8/124")
    assert_nets ["8::8:8:8/128"], rule.from_list(family)
    rule.from_host("@8::8:8:8/124@8::8:4:4/124")
    assert_nets ["8::8:4:4/128","8::8:8:8/128"], rule.from_list(family)
    rule.from_host("@google-public-dns-a.google.com")
    assert_nets ["2001:4860:4860::8888/128"], rule.from_list(family)
    rule.from_host("@google-public-dns-a.google.com@google-public-dns-b.google.com")
    assert_nets ["2001:4860:4860::8844/128", "2001:4860:4860::8888/128"], rule.from_list(family)
    rule.from_host("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAGgoogle-public-dns-a.google.com@google-public-dns-a.google.com@8::8:8:8/124@8::8:4:4/124")
    assert_nets ["1::1:1:1/128", "1::1:1:2/128", "2::2:2:2/128", "8::8:4:4/128", "8::8:8:8/128", "2001:4860:4860::8888/128"], rule.from_list(family)
    rule.from_host("TEST")
    assert_nets ["1::1:1:1/128", "1::1:1:2/128", "2::2:2:2/127"], rule.from_list(family)
  end

  def test_from_list_v6_me
    rule = create_rule
    family = Construqt::Addresses::IPV6
    assert_nets [], rule.from_list(family)
    rule.from_me
    assert_nets ["5::5:5:5/128", "5::5:5:6/128", "5::5:6:5/128", "5::5:6:6/128"], rule.from_list(family)
    rule.from_net("TEST")
    assert_nets ["1::1:1:0/124", "2::2:2:0/124", "5::5:5:5/128", "5::5:5:6/128", "5::5:6:5/128", "5::5:6:6/128"], rule.from_list(family)
    rule.from_me.include_routes
    assert_nets ["1::1:1:0/124",
                 "2::2:2:0/124",
                 "5::5:5:5/128",
                 "5::5:5:6/128",
                 "5::5:6:5/128",
                 "5::5:6:6/128",
                 "11::11:11:0/124",
                 "12::12:12:0/124"], rule.from_list(family)
  end

  def test_from_list_v4_me
    rule = create_rule
    family = Construqt::Addresses::IPV4
    assert_nets [], rule.from_list(family)
    rule.from_me
    assert_nets ["5.5.5.5/32", "5.5.5.6/32", "5.5.6.5/32", "5.5.6.6/32"], rule.from_list(family)
    rule.from_net("TEST")
    assert_nets ["1.1.1.0/24", "2.2.2.0/24", "5.5.5.5/32", "5.5.5.6/32", "5.5.6.5/32", "5.5.6.6/32"], rule.from_list(family)
    rule.from_me.include_routes
    assert_nets ["1.1.1.0/24",
                 "2.2.2.0/24",
                 "5.5.5.5/32",
                 "5.5.5.6/32",
                 "5.5.6.5/32",
                 "5.5.6.6/32",
                 "11.11.11.0/24",
                 "12.12.12.0/24"], rule.from_list(family)
  end

  def test_from_list_v6_my_net
    rule = create_rule
    family = Construqt::Addresses::IPV6
    assert_nets [], rule.from_list(family)
    rule.from_my_net
    assert_nets ["5::5:5:0/124", "5::5:6:0/124"], rule.from_list(family)
    rule.from_net("TEST")
    assert_nets ["1::1:1:0/124", "2::2:2:0/124", "5::5:5:0/124", "5::5:6:0/124"], rule.from_list(family)
    rule.from_my_net.include_routes
    assert_nets ["1::1:1:0/124", "2::2:2:0/124", "5::5:5:0/124", "5::5:6:0/124", "11::11:11:0/124", "12::12:12:0/124"], rule.from_list(family)
  end

  def test_from_list_v4_my_net
    rule = create_rule
    family = Construqt::Addresses::IPV4
    assert_nets [], rule.from_list(family)
    rule.from_my_net
    assert_nets ["5.5.5.0/24", "5.5.6.0/24"], rule.from_list(family)
    rule.from_net("TEST")
    assert_nets ["1.1.1.0/24", "2.2.2.0/24", "5.5.5.0/24", "5.5.6.0/24"], rule.from_list(family)
    rule.from_my_net.include_routes
    assert_nets ["1.1.1.0/24",
                 "2.2.2.0/24",
                 "5.5.5.0/24",
                 "5.5.6.0/24",
                 "11.11.11.0/24",
                 "12.12.12.0/24"], rule.from_list(family)
  end

  def test_to_list_v4_to_net_iface_network
    rule = create_rule
    family = Construqt::Addresses::IPV4
    assert_nets [], rule.to_list(family)
    rule.to_net
    assert_nets ["5.5.5.0/24", "5.5.6.0/24"], rule.to_list(family)
    rule.to_net.include_routes
    assert_nets ["5.5.5.0/24", "5.5.6.0/24", "11.11.11.0/24", "12.12.12.0/24"], rule.to_list(family)
  end

  def test_to_list_v4_to_net_parameter
    rule = create_rule
    family = Construqt::Addresses::IPV4
    assert_nets [], rule.to_list(family)
    rule.to_net("UNKNOWN_TAG")
    assert_nets [], rule.to_list(family)
    rule.to_net("FIRST_NET_1_TAG#FIRST_NET_2_TAG")
    assert_nets ["1.1.1.0/24"], rule.to_list(family)
    rule.to_net("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG")
    assert_nets ["1.1.1.0/24", "2.2.2.0/24"], rule.to_list(family)
    rule.to_net("@8.8.8.8/24")
    assert_nets ["8.8.8.0/24"], rule.to_list(family)
    rule.to_net("@8.8.8.8/24@8.8.4.4/24")
    assert_nets ["8.8.4.0/24","8.8.8.0/24"], rule.to_list(family)
    rule.to_net("@www.slashdot.org")
    assert_nets ["216.34.181.48/32"], rule.to_list(family)
    rule.to_net("@www.slashdot.org@heise.de")
    assert_nets ["193.99.144.80/32", "216.34.181.48/32"], rule.to_list(family)
    rule.to_net("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG@www.slashdot.org@heise.de@8.8.8.8/24@8.8.4.4/24")
    assert_nets ["1.1.1.0/24", "2.2.2.0/24", "8.8.4.0/24", "8.8.8.0/24", "193.99.144.80/32", "216.34.181.48/32"], rule.to_list(family)
    rule.to_net("TEST")
    assert_nets ["1.1.1.0/24", "2.2.2.0/24"], rule.to_list(family)
  end

  def test_to_list_v4_to_host_iface_network
    rule = create_rule
    family = Construqt::Addresses::IPV4
    assert_nets [], rule.to_list(family)
    rule.to_host
    assert_nets ["5.5.5.5/32", "5.5.5.6/32", "5.5.6.5/32", "5.5.6.6/32"], rule.to_list(family)
    rule.to_host.include_routes
    assert_nets ["5.5.5.5/32",
                 "5.5.5.6/32",
                 "5.5.6.5/32",
                 "5.5.6.6/32",
                 "11.11.11.0/24",
                 "12.12.12.0/24"], rule.to_list(family)
  end

  def test_to_list_v4_to_host_parameter
    rule = create_rule
    family = Construqt::Addresses::IPV4
    assert_nets [], rule.to_list(family)
    rule.to_host("UNKNOWN_TAG")
    assert_nets [], rule.to_list(family)
    rule.to_host("FIRST_NET_1_TAG#FIRST_NET_2_TAG")
    assert_nets ["1.1.1.1/32", "1.1.1.2/32"], rule.to_list(family)
    rule.to_host("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG")
    assert_nets ["1.1.1.1/32", "1.1.1.2/32", "2.2.2.2/31"], rule.to_list(family)
    rule.to_host("@8.8.8.8/24")
    assert_nets ["8.8.8.8/32"], rule.to_list(family)
    rule.to_host("@8.8.8.8/24@8.8.4.4/24")
    assert_nets ["8.8.4.4/32","8.8.8.8/32"], rule.to_list(family)
    rule.to_host("@8.8.8.8@8.8.4.4")
    assert_nets ["8.8.4.4/32","8.8.8.8/32"], rule.to_list(family)
    rule.to_host("@www.slashdot.org")
    assert_nets ["216.34.181.48/32"], rule.to_list(family)
    rule.to_host("@www.slashdot.org@heise.de")
    assert_nets ["193.99.144.80/32", "216.34.181.48/32"], rule.to_list(family)
    rule.to_host("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG@www.slashdot.org@heise.de@8.8.8.8/24@8.8.4.4/24")
    assert_nets ["1.1.1.1/32", "1.1.1.2/32", "2.2.2.2/31", "8.8.4.4/32", "8.8.8.8/32", "193.99.144.80/32", "216.34.181.48/32"], rule.to_list(family)
    rule.to_host("TEST")
    assert_nets ["1.1.1.1/32", "1.1.1.2/32", "2.2.2.2/31"], rule.to_list(family)
  end

  def test_to_list_v6_to_net_iface_network
    rule = create_rule
    family = Construqt::Addresses::IPV6
    assert_nets [], rule.to_list(family)
    rule.to_net
    assert_nets ["5::5:5:0/124", "5::5:6:0/124"], rule.to_list(family)
    rule.to_net.include_routes
    assert_nets ["5::5:5:0/124", "5::5:6:0/124", "11::11:11:0/124", "12::12:12:0/124"], rule.to_list(family)
  end

  def test_to_list_v6_to_net_parameter
    rule = create_rule
    family = Construqt::Addresses::IPV6
    assert_nets [], rule.to_list(family)
    rule.to_net("UNKNOWN_TAG")
    assert_nets [], rule.to_list(family)
    rule.to_net("FIRST_NET_1_TAG#FIRST_NET_2_TAG")
    assert_nets ["1::1:1:0/124"], rule.to_list(family)
    rule.to_net("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG")
    assert_nets ["1::1:1:0/124", "2::2:2:0/124"], rule.to_list(family)
    rule.to_net("@8::8:8:8/124")
    assert_nets ["8::8:8:0/124"], rule.to_list(family)
    rule.to_net("@8::8:8:8/124@8::8:4:4/124")
    assert_nets ["8::8:4:0/124","8::8:8:0/124"], rule.to_list(family)
    rule.to_net("@google-public-dns-a.google.com")
    assert_nets ["2001:4860:4860::8888/128"], rule.to_list(family)
    rule.to_net("@google-public-dns-a.google.com@google-public-dns-b.google.com")
    assert_nets ["2001:4860:4860::8844/128", "2001:4860:4860::8888/128"], rule.to_list(family)
    rule.to_net("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG@google-public-dns-a.google.com@google-public-dns-b.google.com@8::8:8:8/124@8::8:4:4/124")
    assert_nets ["1::1:1:0/124", "2::2:2:0/124", "8::8:4:0/124", "8::8:8:0/124", "2001:4860:4860::8844/128", "2001:4860:4860::8888/128"], rule.to_list(family)
    rule.to_net("TEST")
    assert_nets ["1::1:1:0/124", "2::2:2:0/124"], rule.to_list(family)
  end

  def test_to_list_v6_to_host_iface_network
    rule = create_rule
    family = Construqt::Addresses::IPV6
    assert_nets [], rule.to_list(family)
    rule.to_host
    assert_nets ["5::5:5:5/128", "5::5:5:6/128", "5::5:6:5/128", "5::5:6:6/128"], rule.to_list(family)
    rule.to_host.include_routes
    assert_nets ["5::5:5:5/128",
                 "5::5:5:6/128",
                 "5::5:6:5/128",
                 "5::5:6:6/128",
                 "11::11:11:0/124",
                 "12::12:12:0/124"], rule.to_list(family)
  end

  def test_to_list_v6_to_host_parameter
    rule = create_rule
    family = Construqt::Addresses::IPV6
    assert_nets [], rule.to_list(family)
    rule.to_host("UNKNOWN_TAG")
    assert_nets [], rule.to_list(family)
    rule.to_host("FIRST_NET_1_TAG#FIRST_NET_2_TAG")
    assert_nets ["1::1:1:1/128", "1::1:1:2/128"], rule.to_list(family)
    rule.to_host("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG")
    assert_nets ["1::1:1:1/128", "1::1:1:2/128", "2::2:2:2/127"], rule.to_list(family)
    rule.to_host("@8::8:8:8/124")
    assert_nets ["8::8:8:8/128"], rule.to_list(family)
    rule.to_host("@8::8:8:8/124@8::8:4:4/124")
    assert_nets ["8::8:4:4/128","8::8:8:8/128"], rule.to_list(family)
    rule.to_host("@google-public-dns-a.google.com")
    assert_nets ["2001:4860:4860::8888/128"], rule.to_list(family)
    rule.to_host("@google-public-dns-a.google.com@google-public-dns-b.google.com")
    assert_nets ["2001:4860:4860::8844/128", "2001:4860:4860::8888/128"], rule.to_list(family)
    rule.to_host("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAGgoogle-public-dns-a.google.com@google-public-dns-a.google.com@8::8:8:8/124@8::8:4:4/124")
    assert_nets ["1::1:1:1/128", "1::1:1:2/128", "2::2:2:2/128", "8::8:4:4/128", "8::8:8:8/128", "2001:4860:4860::8888/128"], rule.to_list(family)
    rule.to_host("TEST")
    assert_nets ["1::1:1:1/128", "1::1:1:2/128", "2::2:2:2/127"], rule.to_list(family)
  end

  def test_to_list_v6_me
    rule = create_rule
    family = Construqt::Addresses::IPV6
    assert_nets [], rule.to_list(family)
    rule.to_me
    assert_nets ["5::5:5:5/128", "5::5:5:6/128", "5::5:6:5/128", "5::5:6:6/128"], rule.to_list(family)
    rule.to_net("TEST")
    assert_nets ["1::1:1:0/124", "2::2:2:0/124", "5::5:5:5/128", "5::5:5:6/128", "5::5:6:5/128", "5::5:6:6/128"], rule.to_list(family)
    rule.to_me.include_routes
    assert_nets ["1::1:1:0/124",
                 "2::2:2:0/124",
                 "5::5:5:5/128",
                 "5::5:5:6/128",
                 "5::5:6:5/128",
                 "5::5:6:6/128",
                 "11::11:11:0/124",
                 "12::12:12:0/124"], rule.to_list(family)
  end

  def test_to_list_v4_me
    rule = create_rule
    family = Construqt::Addresses::IPV4
    assert_nets [], rule.to_list(family)
    rule.to_me
    assert_nets ["5.5.5.5/32", "5.5.5.6/32", "5.5.6.5/32", "5.5.6.6/32"], rule.to_list(family)
    rule.to_net("TEST")
    assert_nets ["1.1.1.0/24", "2.2.2.0/24", "5.5.5.5/32", "5.5.5.6/32", "5.5.6.5/32", "5.5.6.6/32"], rule.to_list(family)
    rule.to_me.include_routes
    assert_nets ["1.1.1.0/24",
                 "2.2.2.0/24",
                 "5.5.5.5/32",
                 "5.5.5.6/32",
                 "5.5.6.5/32",
                 "5.5.6.6/32",
                 "11.11.11.0/24",
                 "12.12.12.0/24"], rule.to_list(family)
  end

  def test_to_list_v6_my_net
    rule = create_rule
    family = Construqt::Addresses::IPV6
    assert_nets [], rule.to_list(family)
    rule.to_my_net
    assert_nets ["5::5:5:0/124", "5::5:6:0/124"], rule.to_list(family)
    rule.to_net("TEST")
    assert_nets ["1::1:1:0/124", "2::2:2:0/124", "5::5:5:0/124", "5::5:6:0/124"], rule.to_list(family)
    rule.to_my_net.include_routes
    assert_nets ["1::1:1:0/124", "2::2:2:0/124", "5::5:5:0/124", "5::5:6:0/124", "11::11:11:0/124", "12::12:12:0/124"], rule.to_list(family)
  end

  def test_to_list_v4_my_net
    rule = create_rule
    family = Construqt::Addresses::IPV4
    assert_nets [], rule.to_list(family)
    rule.to_my_net
    assert_nets ["5.5.5.0/24", "5.5.6.0/24"], rule.to_list(family)
    rule.to_net("TEST")
    assert_nets ["1.1.1.0/24", "2.2.2.0/24", "5.5.5.0/24", "5.5.6.0/24"], rule.to_list(family)
    rule.to_my_net.include_routes
    assert_nets ["1.1.1.0/24",
                 "2.2.2.0/24",
                 "5.5.5.0/24",
                 "5.5.6.0/24",
                 "11.11.11.0/24",
                 "12.12.12.0/24"], rule.to_list(family)
  end

  def test_rule_to_list_from_tag
    rule = create_rule
    rule.to_host("TESTIPV4")
    rule.from_host("TESTIPV4")
    assert_nets ["1.1.1.1/32", "1.1.1.2/32"], rule.to_list(Construqt::Addresses::IPV4)
    assert_nets ["1.1.1.1/32", "1.1.1.2/32"], rule.from_list(Construqt::Addresses::IPV4)
    assert_nets [], rule.to_list(Construqt::Addresses::IPV6)
    assert_nets [], rule.from_list(Construqt::Addresses::IPV6)

    rule.to_host("TESTIPV6")
    rule.from_host("TESTIPV6")
    assert_nets ["1::1:1:1/128", "1::1:1:2/128"], rule.to_list(Construqt::Addresses::IPV6)
    assert_nets ["1::1:1:1/128", "1::1:1:2/128"], rule.from_list(Construqt::Addresses::IPV6)
    assert_nets [], rule.to_list(Construqt::Addresses::IPV4)
    assert_nets [], rule.from_list(Construqt::Addresses::IPV4)
  end

  def test_rule_to_list_from_at
    rule = create_rule
    rule.to_host("@8.8.8.8")
    rule.from_host("@8.8.8.8")
    assert_nets ["8.8.8.8/32"], rule.to_list(Construqt::Addresses::IPV4)
    assert_nets ["8.8.8.8/32"], rule.from_list(Construqt::Addresses::IPV4)
    assert_nets [], rule.to_list(Construqt::Addresses::IPV6)
    assert_nets [], rule.from_list(Construqt::Addresses::IPV6)

    rule.to_host("@8::8:8:8")
    rule.from_host("@8::8:8:8")
    assert_nets [], rule.to_list(Construqt::Addresses::IPV4)
    assert_nets [], rule.from_list(Construqt::Addresses::IPV4)
    assert_nets ["8::8:8:8/128"], rule.to_list(Construqt::Addresses::IPV6)
    assert_nets ["8::8:8:8/128"], rule.from_list(Construqt::Addresses::IPV6)
  end

  ####################
  #
  def test_forward_from_to_host_connection_port_22_from_is_inside_empty_empty
    #    to_from = connection_from_inside([], [])
    fw = Construqt::Firewalls.add() do |fw|
      fw.forward do |forward|
        forward.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_inside.connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{FORWARD} -i testif -p tcp -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -i testif -p icmp -m state --state RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT",
      "{FORWARD} -o testif -p tcp -m state --state NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -o testif -p icmp -m state --state NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT"
    ], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
  end

  #
  def test_forward_from_to_host_connection_port_22_from_is_inside_empty_2
    #    to_from = connection_from_inside([], ["@8.8.8.8@9.9.9.9"])
    fw = Construqt::Firewalls.add() do |fw|
      fw.forward do |forward|
        forward.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_inside.to_host("@1.1.1.1@2.2.2.2").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{FORWARD} -i testif -p tcp -s 1.1.1.1/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -i testif -p tcp -s 2.2.2.2/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -i testif -p icmp -s 1.1.1.1/32 -m state --state RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT",
      "{FORWARD} -i testif -p icmp -s 2.2.2.2/32 -m state --state RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT",
      "{FORWARD} -o testif -p tcp -d 1.1.1.1/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -o testif -p tcp -d 2.2.2.2/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -o testif -p icmp -d 1.1.1.1/32 -m state --state NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT",
      "{FORWARD} -o testif -p icmp -d 2.2.2.2/32 -m state --state NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT"
    ], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
  end

  #
  def test_forward_from_to_host_connection_port_22_from_is_inside_2_empty
    #    to_from = connection_from_inside(["@1.1.1.1@2.2.2.2"], [])
    fw = Construqt::Firewalls.add() do |fw|
      fw.forward do |forward|
        forward.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_inside.from_host("@8.8.8.8@7.7.7.7").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{FORWARD} -i testif -p tcp -d 7.7.7.7/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -i testif -p tcp -d 8.8.8.8/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -i testif -p icmp -d 7.7.7.7/32 -m state --state RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT",
      "{FORWARD} -i testif -p icmp -d 8.8.8.8/32 -m state --state RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT",
      "{FORWARD} -o testif -p tcp -s 7.7.7.7/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -o testif -p tcp -s 8.8.8.8/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -o testif -p icmp -s 7.7.7.7/32 -m state --state NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT",
      "{FORWARD} -o testif -p icmp -s 8.8.8.8/32 -m state --state NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT"
    ], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
  end

  #
  def test_forward_from_to_host_connection_port_22_from_is_inside_2_3
    #    to_from = connection_from_inside(["@1.1.1.1@2.2.2.2"], ["@7.7.7.7@8.8.8.8@9.9.9.9"])
    fw = Construqt::Firewalls.add() do |fw|
      fw.forward do |forward|
        forward.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_inside.from_host("@8.8.8.8@9.9.9.9").to_host("@1.1.1.1@2.2.2.2@3.3.3.3").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{nL5OYBa2b2TwKcuJ2GrMQ} -s 1.1.1.1/32 -j ACCEPT",
      "{nL5OYBa2b2TwKcuJ2GrMQ} -s 2.2.2.2/32 -j ACCEPT",
      "{nL5OYBa2b2TwKcuJ2GrMQ} -s 3.3.3.3/32 -j ACCEPT",
      "{FORWARD} -i testif -p tcp -d 8.8.8.8/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -j nL5OYBa2b2TwKcuJ2GrMQ",
      "{FORWARD} -i testif -p tcp -d 9.9.9.9/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -j nL5OYBa2b2TwKcuJ2GrMQ",
      "{FORWARD} -i testif -p icmp -d 8.8.8.8/32 -m state --state RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j nL5OYBa2b2TwKcuJ2GrMQ",
      "{FORWARD} -i testif -p icmp -d 9.9.9.9/32 -m state --state RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j nL5OYBa2b2TwKcuJ2GrMQ",
      "{0DdyfHGKehr9zJaOhAtKg} -d 1.1.1.1/32 -j ACCEPT",
      "{0DdyfHGKehr9zJaOhAtKg} -d 2.2.2.2/32 -j ACCEPT",
      "{0DdyfHGKehr9zJaOhAtKg} -d 3.3.3.3/32 -j ACCEPT",
      "{FORWARD} -o testif -p tcp -s 8.8.8.8/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -j 0DdyfHGKehr9zJaOhAtKg",
      "{FORWARD} -o testif -p tcp -s 9.9.9.9/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -j 0DdyfHGKehr9zJaOhAtKg",
      "{FORWARD} -o testif -p icmp -s 8.8.8.8/32 -m state --state NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j 0DdyfHGKehr9zJaOhAtKg",
      "{FORWARD} -o testif -p icmp -s 9.9.9.9/32 -m state --state NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j 0DdyfHGKehr9zJaOhAtKg"
    ], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
  end

  #
  def test_forward_from_to_host_connection_port_22_from_is_inside_3_2
    fw = Construqt::Firewalls.add() do |fw|
      fw.forward do |forward|
        forward.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_inside.from_host("@7.7.7.7@8.8.8.8@9.9.9.9").to_host("@1.1.1.1@2.2.2.2").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{bVQPtbyB3l6B555v3EmjdQ} -d 7.7.7.7/32 -j ACCEPT",
      "{bVQPtbyB3l6B555v3EmjdQ} -d 8.8.8.8/32 -j ACCEPT",
      "{bVQPtbyB3l6B555v3EmjdQ} -d 9.9.9.9/32 -j ACCEPT",
      "{FORWARD} -i testif -p tcp -s 1.1.1.1/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -j bVQPtbyB3l6B555v3EmjdQ",
      "{FORWARD} -i testif -p tcp -s 2.2.2.2/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -j bVQPtbyB3l6B555v3EmjdQ",
      "{FORWARD} -i testif -p icmp -s 1.1.1.1/32 -m state --state RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j bVQPtbyB3l6B555v3EmjdQ",
      "{FORWARD} -i testif -p icmp -s 2.2.2.2/32 -m state --state RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j bVQPtbyB3l6B555v3EmjdQ",
      "{t4S1Uc5aX1Zf4gdZNBKczw} -s 7.7.7.7/32 -j ACCEPT",
      "{t4S1Uc5aX1Zf4gdZNBKczw} -s 8.8.8.8/32 -j ACCEPT",
      "{t4S1Uc5aX1Zf4gdZNBKczw} -s 9.9.9.9/32 -j ACCEPT",
      "{FORWARD} -o testif -p tcp -d 1.1.1.1/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -j t4S1Uc5aX1Zf4gdZNBKczw",
      "{FORWARD} -o testif -p tcp -d 2.2.2.2/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -j t4S1Uc5aX1Zf4gdZNBKczw",
      "{FORWARD} -o testif -p icmp -d 1.1.1.1/32 -m state --state NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j t4S1Uc5aX1Zf4gdZNBKczw",
      "{FORWARD} -o testif -p icmp -d 2.2.2.2/32 -m state --state NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j t4S1Uc5aX1Zf4gdZNBKczw"
    ], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
  end

  def test_forward_from_to_host_connection_port_22_from_is_outside_3_2
    #    to_from = connection_from_inside(["@1.1.1.1@2.2.2.2@3.3.3.3"], ["@1.1.1.1@2.2.2.2"])
    fw = Construqt::Firewalls.add() do |fw|
      fw.forward do |forward|
        forward.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_outside.from_host("@8.8.8.8").to_host("@1.1.1.1").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{FORWARD} -i testif -p tcp -s 8.8.8.8/32 -d 1.1.1.1/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -i testif -p icmp -s 8.8.8.8/32 -d 1.1.1.1/32 -m state --state NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT",
      "{FORWARD} -o testif -p tcp -s 1.1.1.1/32 -d 8.8.8.8/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -o testif -p icmp -s 1.1.1.1/32 -d 8.8.8.8/32 -m state --state RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT"
    ], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
  end

  ####################
  #
  def test_forward_from_to_host_connection_port_22_from_is_inside_1_1
    fw = Construqt::Firewalls.add() do |fw|
      fw.forward do |forward|
        forward.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_inside.from_host("@8.8.8.8").to_host("@1.1.1.1").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{FORWARD} -i testif -p tcp -s 1.1.1.1/32 -d 8.8.8.8/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -i testif -p icmp -s 1.1.1.1/32 -d 8.8.8.8/32 -m state --state RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT",
      "{FORWARD} -o testif -p tcp -s 8.8.8.8/32 -d 1.1.1.1/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -o testif -p icmp -s 8.8.8.8/32 -d 1.1.1.1/32 -m state --state NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT"
    ], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
  end

  #
  def test_host_from_to_host_connection_port_22_from_is_outside_1_1
    fw = Construqt::Firewalls.add() do |fw|
      fw.host do |host|
        host.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_outside.from_host("@8.8.8.8").to_host("@1.1.1.1").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Ubuntu::Firewall.write_host(fw, fw.get_host, "testif", writer)
    assert_equal [
      "{INPUT} -i testif -p tcp -s 8.8.8.8/32 -d 1.1.1.1/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{INPUT} -i testif -p icmp -s 8.8.8.8/32 -d 1.1.1.1/32 -m state --state NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT",
      "{OUTPUT} -o testif -p tcp -s 1.1.1.1/32 -d 8.8.8.8/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{OUTPUT} -o testif -p icmp -s 1.1.1.1/32 -d 8.8.8.8/32 -m state --state RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT"
    ], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
  end

  def test_forward_connection_from_me_to_8_8_8_8_port_22_inside_1_1
    fw = Construqt::Firewalls.add() do |fw|
      fw.forward do |forward|
        forward.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_inside.from_host("@1.1.1.1").to_host("@8.8.8.8").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{FORWARD} -i testif -p tcp -s 8.8.8.8/32 -d 1.1.1.1/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -i testif -p icmp -s 8.8.8.8/32 -d 1.1.1.1/32 -m state --state RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT",
      "{FORWARD} -o testif -p tcp -s 1.1.1.1/32 -d 8.8.8.8/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -o testif -p icmp -s 1.1.1.1/32 -d 8.8.8.8/32 -m state --state NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT"
    ], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
  end

  #
  def test_host_connection_from_me_to_8_8_8_8_port_22_outside_1_1
    fw = Construqt::Firewalls.add() do |fw|
      fw.host do |host|
        host.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_outside.from_host("@1.1.1.1").to_host("@8.8.8.8").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Ubuntu::Firewall.write_host(fw, fw.get_host, "testif", writer)
    assert_equal [
      "{INPUT} -i testif -p tcp -s 1.1.1.1/32 -d 8.8.8.8/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{INPUT} -i testif -p icmp -s 1.1.1.1/32 -d 8.8.8.8/32 -m state --state NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT",
      "{OUTPUT} -o testif -p tcp -s 8.8.8.8/32 -d 1.1.1.1/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{OUTPUT} -o testif -p icmp -s 8.8.8.8/32 -d 1.1.1.1/32 -m state --state RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT"
    ], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
  end

  ######################

  def test_log_from_is_inside
    fw = Construqt::Firewalls.add() do |fw|
      fw.host do |host|
        host.add.action(Construqt::Firewalls::Actions::DROP).log("TEST-LOG").from_is_inside
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Ubuntu::Firewall.write_host(fw, fw.get_host, "testif", writer)
    assert_equal [
      "{INPUT} -i testif -j NFLOG --nflog-prefix TEST-LOG:i:testif",
      "{INPUT} -i testif -j DROP",
      "{OUTPUT} -o testif -j NFLOG --nflog-prefix :TEST-LOG:o:testif",
      "{OUTPUT} -o testif -j DROP"
    ], writer.ipv4.rows
    assert_equal [
      "{INPUT} -i testif -j NFLOG --nflog-prefix TEST-LOG:i:testif",
      "{INPUT} -i testif -j DROP",
      "{OUTPUT} -o testif -j NFLOG --nflog-prefix :TEST-LOG:o:testif",
      "{OUTPUT} -o testif -j DROP"
    ], writer.ipv6.rows
  end

  #
  def test_log_from_is_outside
    fw = Construqt::Firewalls.add() do |fw|
      fw.host do |host|
        host.add.action(Construqt::Firewalls::Actions::DROP).log("TEST-LOG").from_is_outside
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Ubuntu::Firewall.write_host(fw, fw.get_host, "testif", writer)
    assert_equal [
      "{INPUT} -i testif -j NFLOG --nflog-prefix TEST-LOG:i:testif",
      "{INPUT} -i testif -j DROP",
      "{OUTPUT} -o testif -j NFLOG --nflog-prefix :TEST-LOG:o:testif",
      "{OUTPUT} -o testif -j DROP"
    ], writer.ipv4.rows
    assert_equal [
      "{INPUT} -i testif -j NFLOG --nflog-prefix TEST-LOG:i:testif",
      "{INPUT} -i testif -j DROP",
      "{OUTPUT} -o testif -j NFLOG --nflog-prefix :TEST-LOG:o:testif",
      "{OUTPUT} -o testif -j DROP"
    ], writer.ipv6.rows
  end

  def test_link_local_from_is_inside
    fw = Construqt::Firewalls.add() do |fw|
      fw.host do |host|
        host.add.action(Construqt::Firewalls::Actions::ACCEPT).link_local
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Ubuntu::Firewall.write_host(fw, fw.get_host, "testif", writer)
    assert_equal [], writer.ipv4.rows
    assert_equal [
      "{N7jb1NKOStBqD0UP7z6ig} -s 5::5:5:0/124 -j ACCEPT",
      "{N7jb1NKOStBqD0UP7z6ig} -s 5::5:6:0/124 -j ACCEPT",
      "{N7jb1NKOStBqD0UP7z6ig} -s fe80::/64 -j ACCEPT",
      "{N7jb1NKOStBqD0UP7z6ig} -s ff02::/16 -j ACCEPT",
      "{INPUT} -i testif -p icmpv6 -d 5::5:5:0/124 -j N7jb1NKOStBqD0UP7z6ig",
      "{INPUT} -i testif -p icmpv6 -d 5::5:6:0/124 -j N7jb1NKOStBqD0UP7z6ig",
      "{INPUT} -i testif -p icmpv6 -d fe80::/64 -j N7jb1NKOStBqD0UP7z6ig",
      "{INPUT} -i testif -p icmpv6 -d ff02::/16 -j N7jb1NKOStBqD0UP7z6ig",
      "{OUTPUT} -o testif -p icmpv6 -d 5::5:5:0/124 -j N7jb1NKOStBqD0UP7z6ig",
      "{OUTPUT} -o testif -p icmpv6 -d 5::5:6:0/124 -j N7jb1NKOStBqD0UP7z6ig",
      "{OUTPUT} -o testif -p icmpv6 -d fe80::/64 -j N7jb1NKOStBqD0UP7z6ig",
      "{OUTPUT} -o testif -p icmpv6 -d ff02::/16 -j N7jb1NKOStBqD0UP7z6ig"
    ], writer.ipv6.rows
  end

  def test_link_local_from_is_outside
    fw = Construqt::Firewalls.add() do |fw|
      fw.host do |host|
        host.add.action(Construqt::Firewalls::Actions::ACCEPT).link_local.from_is_outside
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Ubuntu::Firewall.write_host(fw, fw.get_host, "testif", writer)
    assert_equal [], writer.ipv4.rows
    assert_equal [
      "{N7jb1NKOStBqD0UP7z6ig} -s 5::5:5:0/124 -j ACCEPT",
      "{N7jb1NKOStBqD0UP7z6ig} -s 5::5:6:0/124 -j ACCEPT",
      "{N7jb1NKOStBqD0UP7z6ig} -s fe80::/64 -j ACCEPT",
      "{N7jb1NKOStBqD0UP7z6ig} -s ff02::/16 -j ACCEPT",
      "{INPUT} -i testif -p icmpv6 -d 5::5:5:0/124 -j N7jb1NKOStBqD0UP7z6ig",
      "{INPUT} -i testif -p icmpv6 -d 5::5:6:0/124 -j N7jb1NKOStBqD0UP7z6ig",
      "{INPUT} -i testif -p icmpv6 -d fe80::/64 -j N7jb1NKOStBqD0UP7z6ig",
      "{INPUT} -i testif -p icmpv6 -d ff02::/16 -j N7jb1NKOStBqD0UP7z6ig",
      "{OUTPUT} -o testif -p icmpv6 -d 5::5:5:0/124 -j N7jb1NKOStBqD0UP7z6ig",
      "{OUTPUT} -o testif -p icmpv6 -d 5::5:6:0/124 -j N7jb1NKOStBqD0UP7z6ig",
      "{OUTPUT} -o testif -p icmpv6 -d fe80::/64 -j N7jb1NKOStBqD0UP7z6ig",
      "{OUTPUT} -o testif -p icmpv6 -d ff02::/16 -j N7jb1NKOStBqD0UP7z6ig"
    ], writer.ipv6.rows
  end
end
