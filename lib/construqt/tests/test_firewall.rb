

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
    def initialize
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
      row = Row.new
      @rows << row
      row
    end
  end
  class TestSection
    attr_reader :jump_destinations
    def initialize
      @jump_destinations = {}
    end
  end

  def create_to_from
    Construqt::Flavour::Ubuntu::Firewall::ToFrom.new
                .bind_section(TestSection.new)
                .factory(TestToFromFactory.new)
                .begin_left("<begin_left>")
                .begin_right("<begin_right>")
                .middle_left("")
                .middle_right("")
                .end_left("<end_left>")
                .end_right("<end_right>")
                .ifname("<ifname>")
                .output_ifname_direction("<output_ifname_direction>")
                .input_ifname_direction("<input_ifname_direction>")
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

  def test_from_to_host_connection_port_22_from_is_outside_empty_empty
    to_from = connection_from_outside([], [])
    assert_array ["{DEFAULT} -o test <begin_left> -p test -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j ACCEPT <end_left>",
                  "{DEFAULT} -i test <begin_right> -p test -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j ACCEPT <end_right>"], to_from.get_factory.rows

  end

  def test_from_to_host_connection_port_22_from_is_outside_empty_2
    to_from = connection_from_outside([], ["@1.1.1.1@2.2.2.2"])
    assert_array [
      "{DEFAULT} -o test <begin_left> -p test -s 1.1.1.1/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j ACCEPT <end_left>",
      "{DEFAULT} -i test <begin_right> -p test -d 1.1.1.1/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j ACCEPT <end_right>",
      "{DEFAULT} -o test <begin_left> -p test -s 2.2.2.2/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j ACCEPT <end_left>",
      "{DEFAULT} -i test <begin_right> -p test -d 2.2.2.2/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j ACCEPT <end_right>"
    ], to_from.get_factory.rows
  end

  def test_from_to_host_connection_port_22_from_is_outside_2_empty
    to_from = connection_from_outside(["@8.8.8.8@9.9.9.9"], [])
    assert_array [
      "{DEFAULT} -o test <begin_left> -p test -d 8.8.8.8/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j ACCEPT <end_left>",
      "{DEFAULT} -i test <begin_right> -p test -s 8.8.8.8/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j ACCEPT <end_right>",
      "{DEFAULT} -o test <begin_left> -p test -d 9.9.9.9/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j ACCEPT <end_left>",
      "{DEFAULT} -i test <begin_right> -p test -s 9.9.9.9/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j ACCEPT <end_right>"
     ], to_from.get_factory.rows
  end

  def test_from_to_host_connection_port_22_from_is_outside_2_3
    to_from = connection_from_outside(["@8.8.8.8@9.9.9.9"], ["@1.1.1.1@2.2.2.2@3.3.3.3"])
    assert_array [
      "{ZU7qVeazKg78Af0qQ9H6fg} -d 1.1.1.1/32 -j ACCEPT <end_left>",
      "{ZU7qVeazKg78Af0qQ9H6fg} -d 2.2.2.2/32 -j ACCEPT <end_left>",
      "{ZU7qVeazKg78Af0qQ9H6fg} -d 3.3.3.3/32 -j ACCEPT <end_left>",
      "{0wUwHMF9NxQGb4HwSxWYA} -s 1.1.1.1/32 -j ACCEPT <end_right>",
      "{0wUwHMF9NxQGb4HwSxWYA} -s 2.2.2.2/32 -j ACCEPT <end_right>",
      "{0wUwHMF9NxQGb4HwSxWYA} -s 3.3.3.3/32 -j ACCEPT <end_right>",
      "{DEFAULT} -o test <begin_left> -p test -s 8.8.8.8/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j ZU7qVeazKg78Af0qQ9H6fg",
      "{DEFAULT} -i test <begin_right> -p test -d 8.8.8.8/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j 0wUwHMF9NxQGb4HwSxWYA",
      "{DEFAULT} -o test <begin_left> -p test -s 9.9.9.9/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j ZU7qVeazKg78Af0qQ9H6fg",
      "{DEFAULT} -i test <begin_right> -p test -d 9.9.9.9/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j 0wUwHMF9NxQGb4HwSxWYA"
    ], to_from.get_factory.rows
  end

  def test_from_to_host_connection_port_22_from_is_outside_3_2
    to_from = connection_from_outside(["@7.7.7.7@8.8.8.8@9.9.9.9"], ["@1.1.1.1@2.2.2.2"])
    assert_array [
      "{p93OyF66gepckhPxZLPg} -s 7.7.7.7/32 -j ACCEPT <end_right>",
      "{p93OyF66gepckhPxZLPg} -s 8.8.8.8/32 -j ACCEPT <end_right>",
      "{p93OyF66gepckhPxZLPg} -s 9.9.9.9/32 -j ACCEPT <end_right>",
      "{bThlmucneqeal9Ww6zmnfQ} -d 7.7.7.7/32 -j ACCEPT <end_left>",
      "{bThlmucneqeal9Ww6zmnfQ} -d 8.8.8.8/32 -j ACCEPT <end_left>",
      "{bThlmucneqeal9Ww6zmnfQ} -d 9.9.9.9/32 -j ACCEPT <end_left>",
      "{DEFAULT} -o test <begin_left> -p test -s 1.1.1.1/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j bThlmucneqeal9Ww6zmnfQ",
      "{DEFAULT} -i test <begin_right> -p test -d 1.1.1.1/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j p93OyF66gepckhPxZLPg",
      "{DEFAULT} -o test <begin_left> -p test -s 2.2.2.2/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j bThlmucneqeal9Ww6zmnfQ",
      "{DEFAULT} -i test <begin_right> -p test -d 2.2.2.2/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j p93OyF66gepckhPxZLPg"
    ], to_from.get_factory.rows
  end
  ##########################################

  def test_from_to_host_connection_port_22_from_is_inside_empty_empty
    to_from = connection_from_inside([], [])
    assert_array [
      "{DEFAULT} -o test <begin_right> -p test -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j ACCEPT <end_right>",
      "{DEFAULT} -i test <begin_left> -p test -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j ACCEPT <end_left>"
    ], to_from.get_factory.rows
  end

  def test_from_to_host_connection_port_22_from_is_inside_empty_2
    to_from = connection_from_inside([], ["@8.8.8.8@9.9.9.9"])
    assert_array [
      "{DEFAULT} -o test <begin_right> -p test -d 8.8.8.8/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j ACCEPT <end_right>",
      "{DEFAULT} -i test <begin_left> -p test -s 8.8.8.8/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j ACCEPT <end_left>",
      "{DEFAULT} -o test <begin_right> -p test -d 9.9.9.9/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j ACCEPT <end_right>",
      "{DEFAULT} -i test <begin_left> -p test -s 9.9.9.9/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j ACCEPT <end_left>"
    ], to_from.get_factory.rows
  end

  def test_from_to_host_connection_port_22_from_is_inside_2_empty
    to_from = connection_from_inside(["@1.1.1.1@2.2.2.2"], [])
    assert_array [
      "{DEFAULT} -o test <begin_right> -p test -s 1.1.1.1/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j ACCEPT <end_right>",
      "{DEFAULT} -i test <begin_left> -p test -d 1.1.1.1/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j ACCEPT <end_left>",
      "{DEFAULT} -o test <begin_right> -p test -s 2.2.2.2/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j ACCEPT <end_right>",
      "{DEFAULT} -i test <begin_left> -p test -d 2.2.2.2/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j ACCEPT <end_left>"
     ], to_from.get_factory.rows
  end

  def test_from_to_host_connection_port_22_from_is_inside_2_3
    to_from = connection_from_inside(["@1.1.1.1@2.2.2.2"], ["@7.7.7.7@8.8.8.8@9.9.9.9"])
    assert_array [
      "{bThlmucneqeal9Ww6zmnfQ} -d 7.7.7.7/32 -j ACCEPT <end_left>",
      "{bThlmucneqeal9Ww6zmnfQ} -d 8.8.8.8/32 -j ACCEPT <end_left>",
      "{bThlmucneqeal9Ww6zmnfQ} -d 9.9.9.9/32 -j ACCEPT <end_left>",
      "{p93OyF66gepckhPxZLPg} -s 7.7.7.7/32 -j ACCEPT <end_right>",
      "{p93OyF66gepckhPxZLPg} -s 8.8.8.8/32 -j ACCEPT <end_right>",
      "{p93OyF66gepckhPxZLPg} -s 9.9.9.9/32 -j ACCEPT <end_right>",
      "{DEFAULT} -o test <begin_right> -p test -d 1.1.1.1/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j p93OyF66gepckhPxZLPg",
      "{DEFAULT} -i test <begin_left> -p test -s 1.1.1.1/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j bThlmucneqeal9Ww6zmnfQ",
      "{DEFAULT} -o test <begin_right> -p test -d 2.2.2.2/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j p93OyF66gepckhPxZLPg",
      "{DEFAULT} -i test <begin_left> -p test -s 2.2.2.2/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j bThlmucneqeal9Ww6zmnfQ"
    ], to_from.get_factory.rows
  end

  def test_from_to_host_connection_port_22_from_is_inside_3_2
    to_from = connection_from_inside(["@1.1.1.1@2.2.2.2@3.3.3.3"], ["@1.1.1.1@2.2.2.2"])
    assert_array [
      "{0wUwHMF9NxQGb4HwSxWYA} -s 1.1.1.1/32 -j ACCEPT <end_right>",
      "{0wUwHMF9NxQGb4HwSxWYA} -s 2.2.2.2/32 -j ACCEPT <end_right>",
      "{0wUwHMF9NxQGb4HwSxWYA} -s 3.3.3.3/32 -j ACCEPT <end_right>",
      "{ZU7qVeazKg78Af0qQ9H6fg} -d 1.1.1.1/32 -j ACCEPT <end_left>",
      "{ZU7qVeazKg78Af0qQ9H6fg} -d 2.2.2.2/32 -j ACCEPT <end_left>",
      "{ZU7qVeazKg78Af0qQ9H6fg} -d 3.3.3.3/32 -j ACCEPT <end_left>",
      "{DEFAULT} -o test <begin_right> -p test -d 1.1.1.1/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j 0wUwHMF9NxQGb4HwSxWYA",
      "{DEFAULT} -i test <begin_left> -p test -s 1.1.1.1/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j ZU7qVeazKg78Af0qQ9H6fg",
      "{DEFAULT} -o test <begin_right> -p test -d 2.2.2.2/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j 0wUwHMF9NxQGb4HwSxWYA",
      "{DEFAULT} -i test <begin_left> -p test -s 2.2.2.2/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j ZU7qVeazKg78Af0qQ9H6fg"
    ], to_from.get_factory.rows
  end


  ##########################################
  def test_from_to_host_connection_port_22_from_is_outside_1_1_input
    rule = create_rule.action(Construqt::Firewalls::Actions::ACCEPT).interface.connection.from_host("@8.8.8.8").to_host("@1.1.1.1").icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22).from_is_outside
    to_from = create_to_from.bind_interface("test", nil, rule).input_only
    Construqt::Flavour::Ubuntu::Firewall.set_port_protocols("-p test", Construqt::Addresses::IPV4, rule, to_from)
    Construqt::Flavour::Ubuntu::Firewall.write_table(Construqt::Addresses::IPV4, rule, to_from)
    assert_equal ["{DEFAULT} -i test <begin_right> -p test -s 8.8.8.8/32 -d 1.1.1.1/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j ACCEPT <end_right>"], to_from.get_factory.rows
  end

  def test_from_to_host_connection_port_22_from_is_outside_1_1_output
    rule = create_rule.action(Construqt::Firewalls::Actions::ACCEPT).interface.connection.from_host("@8.8.8.8").to_host("@1.1.1.1").icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22).from_is_outside
    to_from = create_to_from.bind_interface("test", nil, rule).output_only
    Construqt::Flavour::Ubuntu::Firewall.set_port_protocols("-p test", Construqt::Addresses::IPV4, rule, to_from)
    Construqt::Flavour::Ubuntu::Firewall.write_table(Construqt::Addresses::IPV4, rule, to_from)
    assert_equal ["{DEFAULT} -o test <begin_left> -p test -s 1.1.1.1/32 -d 8.8.8.8/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j ACCEPT <end_left>"], to_from.get_factory.rows
  end

  def test_connection_from_me_to_8_8_8_8_port_22_inside_1_1_input
    rule = create_rule.action(Construqt::Firewalls::Actions::ACCEPT).interface.connection.from_host("@1.1.1.1").to_host("@8.8.8.8").icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22).from_is_inside
    to_from = create_to_from.bind_interface("test", nil, rule).input_only
    Construqt::Flavour::Ubuntu::Firewall.set_port_protocols("-p test", Construqt::Addresses::IPV4, rule, to_from)
    Construqt::Flavour::Ubuntu::Firewall.write_table(Construqt::Addresses::IPV4, rule, to_from)
    assert_equal ["{DEFAULT} -i test <begin_left> -p test -s 8.8.8.8/32 -d 1.1.1.1/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j ACCEPT <end_left>"], to_from.get_factory.rows
  end

  def test_connection_from_me_to_8_8_8_8_port_22_inside_1_1_output
    rule = create_rule.action(Construqt::Firewalls::Actions::ACCEPT).interface.connection.from_host("@1.1.1.1").to_host("@8.8.8.8").icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22).from_is_inside
    to_from = create_to_from.bind_interface("test", nil, rule).output_only
    Construqt::Flavour::Ubuntu::Firewall.set_port_protocols("-p test", Construqt::Addresses::IPV4, rule, to_from)
    Construqt::Flavour::Ubuntu::Firewall.write_table(Construqt::Addresses::IPV4, rule, to_from)
    assert_equal ["{DEFAULT} -o test <begin_right> -p test -s 1.1.1.1/32 -d 8.8.8.8/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j ACCEPT <end_right>"], to_from.get_factory.rows
  end

  def connection_from_outside(from_hosts, to_hosts)
    rule = create_rule.action(Construqt::Firewalls::Actions::ACCEPT).interface.connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22).from_is_outside
    from_hosts.each { |host| rule.from_host(host) }
    to_hosts.each { |host| rule.to_host(host) }
    to_from = create_to_from.bind_interface("test", nil, rule)
    Construqt::Flavour::Ubuntu::Firewall.set_port_protocols("-p test", Construqt::Addresses::IPV4, rule, to_from)
    Construqt::Flavour::Ubuntu::Firewall.write_table(Construqt::Addresses::IPV4, rule, to_from)
    to_from
  end

  def test_from_to_host_connection_port_22_from_is_outside_1_1
    to_from = connection_from_outside(["@8.8.8.8"], ["@1.1.1.1"])
    assert_equal ["{DEFAULT} -o test <begin_left> -p test -s 1.1.1.1/32 -d 8.8.8.8/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j ACCEPT <end_left>",
                  "{DEFAULT} -i test <begin_right> -p test -s 8.8.8.8/32 -d 1.1.1.1/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j ACCEPT <end_right>"], to_from.get_factory.rows
  end

  def connection_from_inside(from_hosts, to_hosts)
    rule = create_rule.action(Construqt::Firewalls::Actions::ACCEPT).interface.connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22).from_is_inside
    from_hosts.each { |host| rule.from_host(host) }
    to_hosts.each { |host| rule.to_host(host) }
    to_from = create_to_from.bind_interface("test", nil, rule)
    Construqt::Flavour::Ubuntu::Firewall.set_port_protocols("-p test", Construqt::Addresses::IPV4, rule, to_from)
    Construqt::Flavour::Ubuntu::Firewall.write_table(Construqt::Addresses::IPV4, rule, to_from)
    to_from
  end

  def test_connection_from_me_to_8_8_8_8_port_22_inside_1_1
    to_from = connection_from_inside(["@1.1.1.1"], ["@8.8.8.8"])
    assert_equal ["{DEFAULT} -o test <begin_right> -p test -s 1.1.1.1/32 -d 8.8.8.8/32 -m state --state NEW,ESTABLISHED -m multiport --dports 22 -m icmp --icmp-type 0/0 -j ACCEPT <end_right>",
                  "{DEFAULT} -i test <begin_left> -p test -s 8.8.8.8/32 -d 1.1.1.1/32 -m state --state RELATED,ESTABLISHED -m multiport --sports 22 -m icmp --icmp-type 8/0 -j ACCEPT <end_left>"], to_from.get_factory.rows
  end


end
