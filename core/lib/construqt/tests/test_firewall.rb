
require 'pry'

require 'test/unit'

require 'ruby-prof'

#RubyProf.start

#$LOAD_PATH.unshift(File.dirname(__FILE__))
#$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

CONSTRUQT_PATH=ENV['CONSTRUQT_PATH']||'./'
[
  "#{CONSTRUQT_PATH}/construqt/core/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/core/lib",
  "#{CONSTRUQT_PATH}/construqt/flavours/nixian/dialects/ubuntu/lib",
#  "#{CONSTRUQT_PATH}/construqt/flavours/ubuntu/lib",
  "#{CONSTRUQT_PATH}/ipaddress/lib"
].each {|path| $LOAD_PATH.unshift(path) }
require 'construqt'
require 'construqt/flavour/nixian'
require 'construqt/flavour/nixian/dialect/ubuntu'

network = Construqt::Networks.add('Construqt-Test-Network')
REGION = Construqt::Regions.add("Construqt-Test-Region", network)
nixian = Construqt::Flavour::Nixian::Factory.new
nixian.add_dialect(Construqt::Flavour::Nixian::Dialect::Ubuntu::Factory.new)
REGION.flavour_factory.add(nixian)


REGION.network.addresses.tag("TEST")
  .add_ip("1.1.1.1/24#FIRST_NET_1_TAG#TESTIPV4#TEST_FROM_FILTER")
  .add_ip("1.1.1.2/24#FIRST_NET_2_TAG#TESTIPV4#TEST_FROM_FILTER")
  .add_ip("1::1:1:1/124#FIRST_NET_1_TAG#TESTIPV6#TEST_FROM_FILTER")
  .add_ip("1::1:1:2/124#FIRST_NET_2_TAG#TESTIPV6#TEST_FROM_FILTER")
REGION.network.addresses.tag("TEST")
  .add_ip("2.2.2.2/24#SECOND_NET_1_TAG#TEST_TO_FILTER")
  .add_ip("2.2.2.3/24#SECOND_NET_2_TAG#TEST_TO_FILTER")
  .add_ip("2::2:2:2/124#SECOND_NET_1_TAG#TEST_TO_FILTER")
  .add_ip("2::2:2:3/124#SECOND_NET_2_TAG#TEST_TO_FILTER")

REGION.network.addresses
  .add_ip("4.4.4.1/24#TEST_TO_FILTER")
  .add_ip("5.5.5.1/24#TEST_FROM_FILTER")

Construqt::Firewalls.add("l-outbound") do |fw|
  fw.forward do |forward|
    forward.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_my_net.to_net("#INDERNET").from_is_outside
  end
end

Construqt::Firewalls.add("l-outbound-host") do |fw|
  fw.host do |host|
    host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_my_net.to_net("#INDERNET").from_is_outside
  end
end

REGION.hosts.add("Construqt-Host-Dhcp", "flavour" => "nixian", "dialect" => "ubuntu") do |cq|
  cq.configip = cq.id ||= Construqt::HostId.create do |my|
    my.interfaces << DHCP_IF = REGION.interfaces.add_device(cq, "v998", "mtu" => 1500,
        "firewalls" => ["l-outbound", "l-outbound-host"],
        'address' => REGION.network.addresses
          .add_ip(Construqt::Addresses::DHCPV4)
          #.add_ip("10.11.12.13/24")
        )
        #)
  end
  REGION.interfaces.add_device(cq, "v999", "mtu" => 1500,
        'address' => REGION.network.addresses.add_ip("172.16.1.1/24"))
end

REGION.hosts.add("Construqt-Host-ipv4", "flavour" => "nixian", "dialect" => "ubuntu") do |cq|
  cq.configip = cq.id ||= Construqt::HostId.create do |my|
    my.interfaces << TEST_IF_IPV4 = REGION.interfaces.add_device(cq, "v998", "mtu" => 1500, 'address' => REGION.network.addresses.add_ip("1.2.2.3"))
  end
end



Construqt::Firewalls.add("l-host-outbound") do |fw|
  fw.host do |host|
    host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_me.to_net("#NA-INTERNET").from_is_inside
  end
end

Construqt::Firewalls.add("l-block") do |fw|
  fw.host do |host|
    host.add.action(Construqt::Firewalls::Actions::ACCEPT).link_local.from_is_outside
    host.add.action(Construqt::Firewalls::Actions::DROP).log("HOST")
  end

  fw.forward do |forward|
    forward.add.action(Construqt::Firewalls::Actions::DROP).log("FORWARD")
  end
end

Construqt::Firewalls.add("l-nat") do |fw|
  fw.nat do |nat|
    nat.add.postrouting.action(Construqt::Firewalls::Actions::SNAT).from_net("@47.47.47.47").to_source.from_is_inside
  end
end

REGION.hosts.add("1-Construqt-Host-ipv4-ipv6", "flavour" => "nixian", "dialect" => "ubuntu") do |cq|
  cq.configip = cq.id ||= Construqt::HostId.create do |my|
    my.interfaces << TEST_IF_ONE_IPV4_AND_IPV6_1 = REGION.interfaces.add_device(cq, "v998", "mtu" => 1500, 'priority' => 4,
                                                                                "firewalls" => ["l-outbound", "l-host-outbound", "l-block"],
                                                                                'address' => REGION.network.addresses
                                                                                                .add_ip("29.29.29.2/24")
                                                                                                .add_ip("29.29.29.47/24")
                                                                                                .add_ip("29::29:29:2/64")
                                                                                                .add_ip("29::29:29:47/64"))
  end
end

REGION.hosts.add("2-Construqt-Host-ipv4-ipv6", "flavour" => "nixian", "dialect" => "ubuntu") do |cq|
  cq.configip = cq.id ||= Construqt::HostId.create do |my|
    my.interfaces << TEST_IF_ONE_IPV4_AND_IPV6_2 = REGION.interfaces.add_device(cq, "v998", "mtu" => 1500, 'priority' => 5,
                                                                                "firewalls" => ["l-outbound", "l-host-outbound", "l-block"],
                                                                                'address' => REGION.network.addresses
                                                                                                .add_ip("29.29.29.3/24")
                                                                                                .add_ip("29.29.29.48/24")
                                                                                                .add_ip("29::29:29:3/64")
                                                                                                .add_ip("29::29:29:48/64"))
  end
end

TEST_VRRP_IF = REGION.interfaces.add_vrrp("vrrp-test",
                                          "vrid" => 19,
                                          "address" => REGION.network.addresses.add_ip("29.29.29.1/32").add_ip("29::29:29:1/128")
  .add_route("2.0.0.0/0#INDERNET", "29.29.29.29")
  .add_route("2000::/3#INDERNET", "29::29:29:29"),
"firewalls" => ["l-nat"],
"interfaces" => [ TEST_IF_ONE_IPV4_AND_IPV6_1, TEST_IF_ONE_IPV4_AND_IPV6_2 ])


REGION.hosts.add("Cinitruqt-Host", "flavour" => "nixian", "dialect" => "ubuntu") do |cq|
  TEST_IF_NOADDR = REGION.interfaces.add_device(cq, "v997", "mtu" => 1500)

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

  def create_rule(iface = TEST_IF)
    rule = Construqt::Firewalls::ForwardEntry.new(nil).action("<action>")
    rule.attached_interface = iface
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
    attr_reader :input, :output, :forward, :prerouting, :postrouting
    def initialize
      @input = TestToFromFactory.new("INPUT")
      @output = TestToFromFactory.new("OUTPUT")
      @forward = TestToFromFactory.new("FORWARD")
      @prerouting = TestToFromFactory.new("PREROUTING")
      @postrouting = TestToFromFactory.new("POSTROUTING")
    end

    def rows
      @input.rows + @output.rows + @forward.rows + @prerouting.rows + @postrouting.rows
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
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall::ToFrom.new("testifname", rule, TestSection.new, TestToFromFactory.new)
  end

  def test_from_list_nil
    rule = create_rule(TEST_IF_NOADDR)
    rule.from_me
    assert_nets ["[MISSING:ipv4]"], rule.from_list(Construqt::Addresses::IPV4)
    assert_nets ["[MISSING:ipv6]"], rule.from_list(Construqt::Addresses::IPV6)
  end

  def test_from_list_from_not_empty_nil
    fw = Construqt::Firewalls.add() do |fw|
      fw.forward do |forward|
        forward.add.action(Construqt::Firewalls::Actions::DNAT).from_net("@0.0.0.0/0").to_me.tcp.dport(80).dport(443).from_is_outside
      end
    end.attach_iface(TEST_IF_NOADDR)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
  end

  def test_port_range
    fw = Construqt::Firewalls.add() do |fw|
      fw.forward do |forward|
        forward.add.action(Construqt::Firewalls::Actions::DNAT).from_net("@8.8.8.8/32").to_net("@9.9.9.9/24").tcp.from_is_outside
        forward.add.action(Construqt::Firewalls::Actions::DNAT).from_net("@8.8.8.8/32").to_net("@9.9.9.9/24").tcp.dport(80).sport(1080).from_is_outside
        forward.add.action(Construqt::Firewalls::Actions::DNAT).from_net("@8.8.8.8/32").to_net("@9.9.9.9/24").tcp.dport(80).dport(96).sport(1080).sport(1096).from_is_outside
        forward.add.action(Construqt::Firewalls::Actions::DNAT).from_net("@8.8.8.8/32").to_net("@9.9.9.9/24").tcp.dport_range(80,90).sport_range(1080,1090).from_is_outside
        forward.add.action(Construqt::Firewalls::Actions::DNAT).from_net("@8.8.8.8/32").to_net("@9.9.9.9/24").tcp.dport(42).sport(4242).dport_range(80,90).sport_range(1080,1090).from_is_outside
      end
    end.attach_iface(TEST_IF_NOADDR)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
     "{FORWARD} -i testif -p tcp -s 8.8.8.8/32 -d 9.9.9.0/24 -j DNAT",
     "{FORWARD} -o testif -p tcp -s 9.9.9.0/24 -d 8.8.8.8/32 -j DNAT",
     "{FORWARD} -i testif -p tcp -s 8.8.8.8/32 -d 9.9.9.0/24 -m multiport --dports 80 --sports 1080 -j DNAT",
     "{FORWARD} -o testif -p tcp -s 9.9.9.0/24 -d 8.8.8.8/32 -m multiport --sports 80 --dports 1080 -j DNAT",
     "{FORWARD} -i testif -p tcp -s 8.8.8.8/32 -d 9.9.9.0/24 -m multiport --dports 80,96 --sports 1080,1096 -j DNAT",
     "{FORWARD} -o testif -p tcp -s 9.9.9.0/24 -d 8.8.8.8/32 -m multiport --sports 80,96 --dports 1080,1096 -j DNAT",
     "{FORWARD} -i testif -p tcp -s 8.8.8.8/32 -d 9.9.9.0/24 -m multiport --dports 80:90 --sports 1080:1090 -j DNAT",
     "{FORWARD} -o testif -p tcp -s 9.9.9.0/24 -d 8.8.8.8/32 -m multiport --sports 80:90 --dports 1080:1090 -j DNAT",
     "{FORWARD} -i testif -p tcp -s 8.8.8.8/32 -d 9.9.9.0/24 -m multiport --dports 42,80:90 --sports 4242,1080:1090 -j DNAT",
     "{FORWARD} -o testif -p tcp -s 9.9.9.0/24 -d 8.8.8.8/32 -m multiport --sports 42,80:90 --dports 4242,1080:1090 -j DNAT"
    ], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
  end

  def test_from_list_from_empty_nil
    fw = Construqt::Firewalls.add() do |fw|
      fw.forward do |forward|
        forward.add.action(Construqt::Firewalls::Actions::DNAT).to_me.tcp.dport(80).dport(443).from_is_outside
      end
    end.attach_iface(TEST_IF_NOADDR)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
  end

  def test_from_list_to_me_only_ipv4
    fw = Construqt::Firewalls.add() do |fw|
      fw.forward do |forward|
        forward.add.action(Construqt::Firewalls::Actions::DNAT).to_me.tcp.dport(80).dport(443).from_is_outside
      end
    end.attach_iface(TEST_IF_IPV4)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{FORWARD} -i testif -p tcp -d 1.2.2.3/32 -m multiport --dports 80,443 -j DNAT",
      "{FORWARD} -o testif -p tcp -s 1.2.2.3/32 -m multiport --sports 80,443 -j DNAT"
    ], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
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
    assert_nets ["[MISSING:ipv4]"], rule.from_list(family)
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
    assert_nets ["[MISSING:ipv4]"], rule.from_list(family)
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
    assert_nets ["[MISSING:ipv6]"], rule.from_list(family)
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
    assert_nets ["[MISSING:ipv6]"], rule.from_list(family)
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
    rule.from_host("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG@google-public-dns-a.google.com@google-public-dns-a.google.com@8::8:8:8/124@8::8:4:4/124")
    assert_nets ["1::1:1:1/128", "1::1:1:2/128", "2::2:2:2/127", "8::8:4:4/128", "8::8:8:8/128", "2001:4860:4860::8888/128"], rule.from_list(family)
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
    assert_nets ["[MISSING:ipv4]"], rule.to_list(family)
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
    assert_nets ["[MISSING:ipv4]"], rule.to_list(family)
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
    assert_nets ["[MISSING:ipv6]"], rule.to_list(family)
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
    assert_nets ["[MISSING:ipv6]"], rule.to_list(family)
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
    rule.to_host("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG@google-public-dns-a.google.com@google-public-dns-a.google.com@8::8:8:8/124@8::8:4:4/124")
    assert_nets ["1::1:1:1/128", "1::1:1:2/128", "2::2:2:2/127", "8::8:4:4/128", "8::8:8:8/128", "2001:4860:4860::8888/128"], rule.to_list(family)
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
    assert_nets ["[MISSING:ipv6]"], rule.to_list(Construqt::Addresses::IPV6)
    assert_nets ["[MISSING:ipv6]"], rule.from_list(Construqt::Addresses::IPV6)

    rule.to_host("TESTIPV6")
    rule.from_host("TESTIPV6")
    assert_nets ["1::1:1:1/128", "1::1:1:2/128"], rule.to_list(Construqt::Addresses::IPV6)
    assert_nets ["1::1:1:1/128", "1::1:1:2/128"], rule.from_list(Construqt::Addresses::IPV6)
    assert_nets ["[MISSING:ipv4]"], rule.to_list(Construqt::Addresses::IPV4)
    assert_nets ["[MISSING:ipv4]"], rule.from_list(Construqt::Addresses::IPV4)
  end

  def test_rule_to_list_from_at
    rule = create_rule
    rule.to_host("@8.8.8.8")
    rule.from_host("@8.8.8.8")
    assert_nets ["8.8.8.8/32"], rule.to_list(Construqt::Addresses::IPV4)
    assert_nets ["8.8.8.8/32"], rule.from_list(Construqt::Addresses::IPV4)
    assert_nets ["[MISSING:ipv6]"], rule.to_list(Construqt::Addresses::IPV6)
    assert_nets ["[MISSING:ipv6]"], rule.from_list(Construqt::Addresses::IPV6)

    rule.to_host("@8::8:8:8")
    rule.from_host("@8::8:8:8")
    assert_nets ["[MISSING:ipv4]"], rule.to_list(Construqt::Addresses::IPV4)
    assert_nets ["[MISSING:ipv4]"], rule.from_list(Construqt::Addresses::IPV4)
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
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{FORWARD} -i testif -p tcp -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -i testif -p icmp -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT",
      "{FORWARD} -o testif -p tcp -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -o testif -p icmp -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT"
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
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{FORWARD} -i testif -p tcp -s 1.1.1.1/32 -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -i testif -p tcp -s 2.2.2.2/32 -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -i testif -p icmp -s 1.1.1.1/32 -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT",
      "{FORWARD} -i testif -p icmp -s 2.2.2.2/32 -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT",
      "{FORWARD} -o testif -p tcp -d 1.1.1.1/32 -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -o testif -p tcp -d 2.2.2.2/32 -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -o testif -p icmp -d 1.1.1.1/32 -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT",
      "{FORWARD} -o testif -p icmp -d 2.2.2.2/32 -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT"
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
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{FORWARD} -i testif -p tcp -d 7.7.7.7/32 -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -i testif -p tcp -d 8.8.8.8/32 -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -i testif -p icmp -d 7.7.7.7/32 -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT",
      "{FORWARD} -i testif -p icmp -d 8.8.8.8/32 -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT",
      "{FORWARD} -o testif -p tcp -s 7.7.7.7/32 -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -o testif -p tcp -s 8.8.8.8/32 -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -o testif -p icmp -s 7.7.7.7/32 -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT",
      "{FORWARD} -o testif -p icmp -s 8.8.8.8/32 -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT"
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
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{iPeobZ7IG2kKI0CfwQ} -s 1.1.1.1/32 -j ACCEPT",
      "{iPeobZ7IG2kKI0CfwQ} -s 2.2.2.2/32 -j ACCEPT",
      "{iPeobZ7IG2kKI0CfwQ} -s 3.3.3.3/32 -j ACCEPT",
      "{iPeobZ7IG2kKI0CfwQ} -j RETURN",
      "{Tr5ZdQoctH7dXWBwFzVVA} -d 8.8.8.8/32 -j iPeobZ7IG2kKI0CfwQ",
      "{Tr5ZdQoctH7dXWBwFzVVA} -d 9.9.9.9/32 -j iPeobZ7IG2kKI0CfwQ",
      "{Tr5ZdQoctH7dXWBwFzVVA} -j RETURN",
      "{FORWARD} -i testif -p tcp -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j Tr5ZdQoctH7dXWBwFzVVA",
      "{FORWARD} -i testif -p icmp -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j Tr5ZdQoctH7dXWBwFzVVA",
      "{WasXXTbxPbzCnpD9JqgfIA} -d 1.1.1.1/32 -j ACCEPT",
      "{WasXXTbxPbzCnpD9JqgfIA} -d 2.2.2.2/32 -j ACCEPT",
      "{WasXXTbxPbzCnpD9JqgfIA} -d 3.3.3.3/32 -j ACCEPT",
      "{WasXXTbxPbzCnpD9JqgfIA} -j RETURN",
      "{ErkobMVYbQVNMcLiAA7A} -s 8.8.8.8/32 -j WasXXTbxPbzCnpD9JqgfIA",
      "{ErkobMVYbQVNMcLiAA7A} -s 9.9.9.9/32 -j WasXXTbxPbzCnpD9JqgfIA",
      "{ErkobMVYbQVNMcLiAA7A} -j RETURN",
      "{FORWARD} -o testif -p tcp -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j ErkobMVYbQVNMcLiAA7A",
      "{FORWARD} -o testif -p icmp -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ErkobMVYbQVNMcLiAA7A"
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
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{gT2VAWpbC806nBxD1zTVg} -d 7.7.7.7/32 -j ACCEPT",
      "{gT2VAWpbC806nBxD1zTVg} -d 8.8.8.8/32 -j ACCEPT",
      "{gT2VAWpbC806nBxD1zTVg} -d 9.9.9.9/32 -j ACCEPT",
      "{gT2VAWpbC806nBxD1zTVg} -j RETURN",
      "{QRenRkNC8fslLevet8auog} -s 1.1.1.1/32 -j gT2VAWpbC806nBxD1zTVg",
      "{QRenRkNC8fslLevet8auog} -s 2.2.2.2/32 -j gT2VAWpbC806nBxD1zTVg",
      "{QRenRkNC8fslLevet8auog} -j RETURN",
      "{FORWARD} -i testif -p tcp -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j QRenRkNC8fslLevet8auog",
      "{FORWARD} -i testif -p icmp -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j QRenRkNC8fslLevet8auog",
      "{sIwP8wZDziROx9HKelprw} -s 7.7.7.7/32 -j ACCEPT",
      "{sIwP8wZDziROx9HKelprw} -s 8.8.8.8/32 -j ACCEPT",
      "{sIwP8wZDziROx9HKelprw} -s 9.9.9.9/32 -j ACCEPT",
      "{sIwP8wZDziROx9HKelprw} -j RETURN",
      "{XukrDZP3wUMxYRArTUJn0w} -d 1.1.1.1/32 -j sIwP8wZDziROx9HKelprw",
      "{XukrDZP3wUMxYRArTUJn0w} -d 2.2.2.2/32 -j sIwP8wZDziROx9HKelprw",
      "{XukrDZP3wUMxYRArTUJn0w} -j RETURN",
      "{FORWARD} -o testif -p tcp -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j XukrDZP3wUMxYRArTUJn0w",
      "{FORWARD} -o testif -p icmp -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j XukrDZP3wUMxYRArTUJn0w"
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
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{FORWARD} -i testif -p tcp -s 8.8.8.8/32 -d 1.1.1.1/32 -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -i testif -p icmp -s 8.8.8.8/32 -d 1.1.1.1/32 -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT",
      "{FORWARD} -o testif -p tcp -s 1.1.1.1/32 -d 8.8.8.8/32 -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -o testif -p icmp -s 1.1.1.1/32 -d 8.8.8.8/32 -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT"
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
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{FORWARD} -i testif -p tcp -s 1.1.1.1/32 -d 8.8.8.8/32 -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -i testif -p icmp -s 1.1.1.1/32 -d 8.8.8.8/32 -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT",
      "{FORWARD} -o testif -p tcp -s 8.8.8.8/32 -d 1.1.1.1/32 -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -o testif -p icmp -s 8.8.8.8/32 -d 1.1.1.1/32 -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT"
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
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_host(fw, fw.get_host, "testif", writer)
    assert_equal [
      "{INPUT} -i testif -p tcp -s 8.8.8.8/32 -d 1.1.1.1/32 -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{INPUT} -i testif -p icmp -s 8.8.8.8/32 -d 1.1.1.1/32 -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT",
      "{OUTPUT} -o testif -p tcp -s 1.1.1.1/32 -d 8.8.8.8/32 -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{OUTPUT} -o testif -p icmp -s 1.1.1.1/32 -d 8.8.8.8/32 -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT"
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
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{FORWARD} -i testif -p tcp -s 8.8.8.8/32 -d 1.1.1.1/32 -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -i testif -p icmp -s 8.8.8.8/32 -d 1.1.1.1/32 -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT",
      "{FORWARD} -o testif -p tcp -s 1.1.1.1/32 -d 8.8.8.8/32 -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -o testif -p icmp -s 1.1.1.1/32 -d 8.8.8.8/32 -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT"
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
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_host(fw, fw.get_host, "testif", writer)
    assert_equal [
      "{INPUT} -i testif -p tcp -s 1.1.1.1/32 -d 8.8.8.8/32 -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{INPUT} -i testif -p icmp -s 1.1.1.1/32 -d 8.8.8.8/32 -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT",
      "{OUTPUT} -o testif -p tcp -s 8.8.8.8/32 -d 1.1.1.1/32 -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{OUTPUT} -o testif -p icmp -s 8.8.8.8/32 -d 1.1.1.1/32 -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT"
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
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_host(fw, fw.get_host, "testif", writer)
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
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_host(fw, fw.get_host, "testif", writer)
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
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_host(fw, fw.get_host, "testif", writer)
    assert_equal [], writer.ipv4.rows
    assert_equal [
      "{uOrdBa2drtysoTwlgKnSwA} -s 5::5:5:0/124 -j ACCEPT",
      "{uOrdBa2drtysoTwlgKnSwA} -s 5::5:6:0/124 -j ACCEPT",
      "{uOrdBa2drtysoTwlgKnSwA} -s fe80::/64 -j ACCEPT",
      "{uOrdBa2drtysoTwlgKnSwA} -s ff02::/16 -j ACCEPT",
      "{uOrdBa2drtysoTwlgKnSwA} -j RETURN",
      "{XnXpWV8ZsaorHpVEPYID0g} -d 5::5:5:0/124 -j uOrdBa2drtysoTwlgKnSwA",
      "{XnXpWV8ZsaorHpVEPYID0g} -d 5::5:6:0/124 -j uOrdBa2drtysoTwlgKnSwA",
      "{XnXpWV8ZsaorHpVEPYID0g} -d fe80::/64 -j uOrdBa2drtysoTwlgKnSwA",
      "{XnXpWV8ZsaorHpVEPYID0g} -d ff02::/16 -j uOrdBa2drtysoTwlgKnSwA",
      "{XnXpWV8ZsaorHpVEPYID0g} -j RETURN",
      "{INPUT} -i testif -p icmpv6 -j XnXpWV8ZsaorHpVEPYID0g",
      "{OUTPUT} -o testif -p icmpv6 -j XnXpWV8ZsaorHpVEPYID0g"
    ], writer.ipv6.rows
  end

  def test_link_local_from_is_outside
    fw = Construqt::Firewalls.add() do |fw|
      fw.host do |host|
        host.add.action(Construqt::Firewalls::Actions::ACCEPT).link_local.from_is_outside
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_host(fw, fw.get_host, "testif", writer)
    assert_equal [], writer.ipv4.rows
    assert_equal [
      "{uOrdBa2drtysoTwlgKnSwA} -s 5::5:5:0/124 -j ACCEPT",
      "{uOrdBa2drtysoTwlgKnSwA} -s 5::5:6:0/124 -j ACCEPT",
      "{uOrdBa2drtysoTwlgKnSwA} -s fe80::/64 -j ACCEPT",
      "{uOrdBa2drtysoTwlgKnSwA} -s ff02::/16 -j ACCEPT",
      "{uOrdBa2drtysoTwlgKnSwA} -j RETURN",
      "{XnXpWV8ZsaorHpVEPYID0g} -d 5::5:5:0/124 -j uOrdBa2drtysoTwlgKnSwA",
      "{XnXpWV8ZsaorHpVEPYID0g} -d 5::5:6:0/124 -j uOrdBa2drtysoTwlgKnSwA",
      "{XnXpWV8ZsaorHpVEPYID0g} -d fe80::/64 -j uOrdBa2drtysoTwlgKnSwA",
      "{XnXpWV8ZsaorHpVEPYID0g} -d ff02::/16 -j uOrdBa2drtysoTwlgKnSwA",
      "{XnXpWV8ZsaorHpVEPYID0g} -j RETURN",
      "{INPUT} -i testif -p icmpv6 -j XnXpWV8ZsaorHpVEPYID0g",
      "{OUTPUT} -o testif -p icmpv6 -j XnXpWV8ZsaorHpVEPYID0g"
    ], writer.ipv6.rows
  end

  def test_nat
    fw = Construqt::Firewalls.add() do |fw|
      fw.nat do |nat|
        nat.ipv4
        nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).from_net("@0.0.0.0/0").to_host("@1.1.1.1").tcp.dport(80).dport(443).to_dest("@8.8.8.8").from_is_outside
        nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).from_net("@0.0.0.0/0").to_host("@1.1.1.2").tcp.dport(80).dport(443).to_dest("@8.8.4.4").from_is_outside

        nat.add.postrouting.action(Construqt::Firewalls::Actions::SNAT).from_net("@47.11.0.0/16").to_net("@0.0.0.0/0").to_source("@9.9.9.9").from_is_inside
        nat.add.postrouting.action(Construqt::Firewalls::Actions::SNAT).from_net("@0.0.0.0/0").to_host("@8.8.8.8").tcp.dport(80).dport(443).to_source("@2.2.2.1").from_is_inside
        nat.add.postrouting.action(Construqt::Firewalls::Actions::SNAT).from_net("@0.0.0.0/0").to_host("@8.8.4.4").tcp.dport(80).dport(443).to_source("@2.2.2.2").from_is_inside
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_nat(fw, fw.get_nat, "testif", writer)
    assert_equal [
      "{PREROUTING} -i testif -p tcp -s 0.0.0.0/0 -d 1.1.1.1/32 -m multiport --dports 80,443 -j DNAT --to-dest 8.8.8.8",
      "{PREROUTING} -i testif -p tcp -s 0.0.0.0/0 -d 1.1.1.2/32 -m multiport --dports 80,443 -j DNAT --to-dest 8.8.4.4",
      "{POSTROUTING} -o testif -s 47.11.0.0/16 -d 0.0.0.0/0 -j SNAT --to-source 9.9.9.9",
      "{POSTROUTING} -o testif -p tcp -s 0.0.0.0/0 -d 8.8.8.8/32 -m multiport --dports 80,443 -j SNAT --to-source 2.2.2.1",
      "{POSTROUTING} -o testif -p tcp -s 0.0.0.0/0 -d 8.8.4.4/32 -m multiport --dports 80,443 -j SNAT --to-source 2.2.2.2"
    ], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
  end

  def test_not_1_1
    fw = Construqt::Firewalls.add() do |fw|
      fw.forward do |forward|
        forward.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_inside.not_from.from_host("@1.1.1.1").to_host("@8.8.8.8").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
        forward.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_inside.from_host("@1.1.1.1").not_to.to_host("@8.8.8.8").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
        forward.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_inside.not_from.from_host("@1.1.1.1").not_to.to_host("@8.8.8.8").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{FORWARD} -i testif -p tcp -s 8.8.8.8/32 ! -d 1.1.1.1/32 -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -i testif -p icmp -s 8.8.8.8/32 ! -d 1.1.1.1/32 -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT",
      "{FORWARD} -o testif -p tcp ! -s 1.1.1.1/32 -d 8.8.8.8/32 -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -o testif -p icmp ! -s 1.1.1.1/32 -d 8.8.8.8/32 -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT",
      "{FORWARD} -i testif -p tcp ! -s 8.8.8.8/32 -d 1.1.1.1/32 -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -i testif -p icmp ! -s 8.8.8.8/32 -d 1.1.1.1/32 -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT",
      "{FORWARD} -o testif -p tcp -s 1.1.1.1/32 ! -d 8.8.8.8/32 -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -o testif -p icmp -s 1.1.1.1/32 ! -d 8.8.8.8/32 -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT",
      "{FORWARD} -i testif -p tcp ! -s 8.8.8.8/32 ! -d 1.1.1.1/32 -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -i testif -p icmp ! -s 8.8.8.8/32 ! -d 1.1.1.1/32 -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT",
      "{FORWARD} -o testif -p tcp ! -s 1.1.1.1/32 ! -d 8.8.8.8/32 -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -o testif -p icmp ! -s 1.1.1.1/32 ! -d 8.8.8.8/32 -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT"
    ], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
  end

  def test_not_empty_2
    fw = Construqt::Firewalls.add() do |fw|
      fw.forward do |forward|
        forward.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_inside.not_from.from_host("@1.1.1.1@2.2.2.2").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
        forward.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_inside.not_to.to_host("@8.8.8.8@7.7.7.7").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{FORWARD} -i testif -p tcp ! -d 1.1.1.1/32 -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -i testif -p tcp ! -d 2.2.2.2/32 -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -i testif -p icmp ! -d 1.1.1.1/32 -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT",
      "{FORWARD} -i testif -p icmp ! -d 2.2.2.2/32 -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT",
      "{FORWARD} -o testif -p tcp ! -s 1.1.1.1/32 -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -o testif -p tcp ! -s 2.2.2.2/32 -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -o testif -p icmp ! -s 1.1.1.1/32 -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT",
      "{FORWARD} -o testif -p icmp ! -s 2.2.2.2/32 -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT",
      "{FORWARD} -i testif -p tcp ! -s 7.7.7.7/32 -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -i testif -p tcp ! -s 8.8.8.8/32 -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j ACCEPT",
      "{FORWARD} -i testif -p icmp ! -s 7.7.7.7/32 -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT",
      "{FORWARD} -i testif -p icmp ! -s 8.8.8.8/32 -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j ACCEPT",
      "{FORWARD} -o testif -p tcp ! -d 7.7.7.7/32 -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -o testif -p tcp ! -d 8.8.8.8/32 -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j ACCEPT",
      "{FORWARD} -o testif -p icmp ! -d 7.7.7.7/32 -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT",
      "{FORWARD} -o testif -p icmp ! -d 8.8.8.8/32 -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j ACCEPT"
    ], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
  end

  def test_not_2_3
    fw = Construqt::Firewalls.add() do |fw|
      fw.forward do |forward|
        forward.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_inside.not_from.from_host("@1.1.1.1@2.2.2.2").to_host("@7.7.7.7@8.8.8.8@9.9.9.9").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
        forward.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_inside.not_to.to_host("@8.8.8.8@7.7.7.7").from_host("@7.7.7.7@8.8.8.8@9.9.9.9").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{sIwP8wZDziROx9HKelprw} -s 7.7.7.7/32 -j ACCEPT",
      "{sIwP8wZDziROx9HKelprw} -s 8.8.8.8/32 -j ACCEPT",
      "{sIwP8wZDziROx9HKelprw} -s 9.9.9.9/32 -j ACCEPT",
      "{sIwP8wZDziROx9HKelprw} -j RETURN",
      "{I3zewsVvinLWrKK7Wc4dA} -d 1.1.1.1/32 -j RETURN",
      "{I3zewsVvinLWrKK7Wc4dA} -d 2.2.2.2/32 -j RETURN",
      "{I3zewsVvinLWrKK7Wc4dA} -j sIwP8wZDziROx9HKelprw",
      "{FORWARD} -i testif -p tcp -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j I3zewsVvinLWrKK7Wc4dA",
      "{FORWARD} -i testif -p icmp -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j I3zewsVvinLWrKK7Wc4dA",
      "{gT2VAWpbC806nBxD1zTVg} -d 7.7.7.7/32 -j ACCEPT",
      "{gT2VAWpbC806nBxD1zTVg} -d 8.8.8.8/32 -j ACCEPT",
      "{gT2VAWpbC806nBxD1zTVg} -d 9.9.9.9/32 -j ACCEPT",
      "{gT2VAWpbC806nBxD1zTVg} -j RETURN",
      "{FPMxJtY8JjfKWxMFP9OLDw} -s 1.1.1.1/32 -j RETURN",
      "{FPMxJtY8JjfKWxMFP9OLDw} -s 2.2.2.2/32 -j RETURN",
      "{FPMxJtY8JjfKWxMFP9OLDw} -j gT2VAWpbC806nBxD1zTVg",
      "{FORWARD} -o testif -p tcp -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j FPMxJtY8JjfKWxMFP9OLDw",
      "{FORWARD} -o testif -p icmp -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j FPMxJtY8JjfKWxMFP9OLDw",
      "{3trynWY1zSiKamIM5V9hQ} -s 7.7.7.7/32 -j RETURN",
      "{3trynWY1zSiKamIM5V9hQ} -s 8.8.8.8/32 -j RETURN",
      "{3trynWY1zSiKamIM5V9hQ} -j gT2VAWpbC806nBxD1zTVg",
      "{FORWARD} -i testif -p tcp -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j 3trynWY1zSiKamIM5V9hQ",
      "{FORWARD} -i testif -p icmp -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j 3trynWY1zSiKamIM5V9hQ",
      "{vNcQPp4uj7YABjmtz1dQ} -d 7.7.7.7/32 -j RETURN",
      "{vNcQPp4uj7YABjmtz1dQ} -d 8.8.8.8/32 -j RETURN",
      "{vNcQPp4uj7YABjmtz1dQ} -j sIwP8wZDziROx9HKelprw",
      "{FORWARD} -o testif -p tcp -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j vNcQPp4uj7YABjmtz1dQ",
      "{FORWARD} -o testif -p icmp -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j vNcQPp4uj7YABjmtz1dQ"
    ], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
  end

  def test_2_not_3
    fw = Construqt::Firewalls.add() do |fw|
      fw.forward do |forward|
        forward.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_inside.from_host("@1.1.1.1@2.2.2.2").not_to.to_host("@7.7.7.7@8.8.8.8@9.9.9.9").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
        forward.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_inside.to_host("@8.8.8.8@7.7.7.7").not_from.from_host("@7.7.7.7@8.8.8.8@9.9.9.9").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{JX0nORdnJqC8u2FGJriOsQ} -s 7.7.7.7/32 -j RETURN",
      "{JX0nORdnJqC8u2FGJriOsQ} -s 8.8.8.8/32 -j RETURN",
      "{JX0nORdnJqC8u2FGJriOsQ} -s 9.9.9.9/32 -j RETURN",
      "{JX0nORdnJqC8u2FGJriOsQ} -j ACCEPT",
      "{mq4jd1nRg75YJUTa83m0g} -d 1.1.1.1/32 -j JX0nORdnJqC8u2FGJriOsQ",
      "{mq4jd1nRg75YJUTa83m0g} -d 2.2.2.2/32 -j JX0nORdnJqC8u2FGJriOsQ",
      "{mq4jd1nRg75YJUTa83m0g} -j RETURN",
      "{FORWARD} -i testif -p tcp -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j mq4jd1nRg75YJUTa83m0g",
      "{FORWARD} -i testif -p icmp -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j mq4jd1nRg75YJUTa83m0g",
      "{PHUYy7LaQoiHgKPa5p7q7A} -d 7.7.7.7/32 -j RETURN",
      "{PHUYy7LaQoiHgKPa5p7q7A} -d 8.8.8.8/32 -j RETURN",
      "{PHUYy7LaQoiHgKPa5p7q7A} -d 9.9.9.9/32 -j RETURN",
      "{PHUYy7LaQoiHgKPa5p7q7A} -j ACCEPT",
      "{U4DG3JULUtRzrLuUMyq6w} -s 1.1.1.1/32 -j PHUYy7LaQoiHgKPa5p7q7A",
      "{U4DG3JULUtRzrLuUMyq6w} -s 2.2.2.2/32 -j PHUYy7LaQoiHgKPa5p7q7A",
      "{U4DG3JULUtRzrLuUMyq6w} -j RETURN",
      "{FORWARD} -o testif -p tcp -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j U4DG3JULUtRzrLuUMyq6w",
      "{FORWARD} -o testif -p icmp -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j U4DG3JULUtRzrLuUMyq6w",
      "{AIlaUU0pMDc1pXufWIXfgg} -s 7.7.7.7/32 -j PHUYy7LaQoiHgKPa5p7q7A",
      "{AIlaUU0pMDc1pXufWIXfgg} -s 8.8.8.8/32 -j PHUYy7LaQoiHgKPa5p7q7A",
      "{AIlaUU0pMDc1pXufWIXfgg} -j RETURN",
      "{FORWARD} -i testif -p tcp -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j AIlaUU0pMDc1pXufWIXfgg",
      "{FORWARD} -i testif -p icmp -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j AIlaUU0pMDc1pXufWIXfgg",
      "{wSvSDuTkCBR4RRctnIpjg} -d 7.7.7.7/32 -j JX0nORdnJqC8u2FGJriOsQ",
      "{wSvSDuTkCBR4RRctnIpjg} -d 8.8.8.8/32 -j JX0nORdnJqC8u2FGJriOsQ",
      "{wSvSDuTkCBR4RRctnIpjg} -j RETURN",
      "{FORWARD} -o testif -p tcp -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j wSvSDuTkCBR4RRctnIpjg",
      "{FORWARD} -o testif -p icmp -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j wSvSDuTkCBR4RRctnIpjg"
    ], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
  end

  def test_not_2_not_3
    fw = Construqt::Firewalls.add() do |fw|
      fw.forward do |forward|
        forward.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_inside.not_from.from_host("@1.1.1.1@2.2.2.2").not_to.to_host("@7.7.7.7@8.8.8.8@9.9.9.9").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
        forward.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_inside.not_to.to_host("@8.8.8.8@7.7.7.7").not_from.from_host("@7.7.7.7@8.8.8.8@9.9.9.9").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{JX0nORdnJqC8u2FGJriOsQ} -s 7.7.7.7/32 -j RETURN",
      "{JX0nORdnJqC8u2FGJriOsQ} -s 8.8.8.8/32 -j RETURN",
      "{JX0nORdnJqC8u2FGJriOsQ} -s 9.9.9.9/32 -j RETURN",
      "{JX0nORdnJqC8u2FGJriOsQ} -j ACCEPT",
      "{IDoervDkCW1GiaqZeQnJA} -d 1.1.1.1/32 -j RETURN",
      "{IDoervDkCW1GiaqZeQnJA} -d 2.2.2.2/32 -j RETURN",
      "{IDoervDkCW1GiaqZeQnJA} -j JX0nORdnJqC8u2FGJriOsQ",
      "{FORWARD} -i testif -p tcp -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j IDoervDkCW1GiaqZeQnJA",
      "{FORWARD} -i testif -p icmp -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j IDoervDkCW1GiaqZeQnJA",
      "{PHUYy7LaQoiHgKPa5p7q7A} -d 7.7.7.7/32 -j RETURN",
      "{PHUYy7LaQoiHgKPa5p7q7A} -d 8.8.8.8/32 -j RETURN",
      "{PHUYy7LaQoiHgKPa5p7q7A} -d 9.9.9.9/32 -j RETURN",
      "{PHUYy7LaQoiHgKPa5p7q7A} -j ACCEPT",
      "{OJ6ne4MtXMQehUOI7Ajmvw} -s 1.1.1.1/32 -j RETURN",
      "{OJ6ne4MtXMQehUOI7Ajmvw} -s 2.2.2.2/32 -j RETURN",
      "{OJ6ne4MtXMQehUOI7Ajmvw} -j PHUYy7LaQoiHgKPa5p7q7A",
      "{FORWARD} -o testif -p tcp -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j OJ6ne4MtXMQehUOI7Ajmvw",
      "{FORWARD} -o testif -p icmp -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j OJ6ne4MtXMQehUOI7Ajmvw",
      "{PXkAftc146vAPJTc4QIr7Q} -s 7.7.7.7/32 -j RETURN",
      "{PXkAftc146vAPJTc4QIr7Q} -s 8.8.8.8/32 -j RETURN",
      "{PXkAftc146vAPJTc4QIr7Q} -j PHUYy7LaQoiHgKPa5p7q7A",
      "{FORWARD} -i testif -p tcp -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j PXkAftc146vAPJTc4QIr7Q",
      "{FORWARD} -i testif -p icmp -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j PXkAftc146vAPJTc4QIr7Q",
      "{kBg9SS5Cgta74ABPRSTlbg} -d 7.7.7.7/32 -j RETURN",
      "{kBg9SS5Cgta74ABPRSTlbg} -d 8.8.8.8/32 -j RETURN",
      "{kBg9SS5Cgta74ABPRSTlbg} -j JX0nORdnJqC8u2FGJriOsQ",
      "{FORWARD} -o testif -p tcp -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j kBg9SS5Cgta74ABPRSTlbg",
      "{FORWARD} -o testif -p icmp -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j kBg9SS5Cgta74ABPRSTlbg"
    ], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
  end

  def test_1_lt_2
    fw = Construqt::Firewalls.add() do |fw|
      fw.forward do |forward|
        forward.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_inside.from_host("@1.1.1.1").to_host("@7.7.7.7@8.8.8.8").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
        forward.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_is_inside.not_to.to_host("@8.8.8.8@7.7.7.7").not_from.from_host("@9.9.9.9").connection.icmp.type(Construqt::Firewalls::ICMP::Ping).tcp.dport(22)
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{q5qOileEfiWcsSA2VF1RqQ} -s 7.7.7.7/32 -j ACCEPT",
      "{q5qOileEfiWcsSA2VF1RqQ} -s 8.8.8.8/32 -j ACCEPT",
      "{q5qOileEfiWcsSA2VF1RqQ} -j RETURN",
      "{FORWARD} -i testif -p tcp -d 1.1.1.1/32 -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j q5qOileEfiWcsSA2VF1RqQ",
      "{FORWARD} -i testif -p icmp -d 1.1.1.1/32 -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j q5qOileEfiWcsSA2VF1RqQ",
      "{GcN7oXzN0S6xWaQvWpJow} -d 7.7.7.7/32 -j ACCEPT",
      "{GcN7oXzN0S6xWaQvWpJow} -d 8.8.8.8/32 -j ACCEPT",
      "{GcN7oXzN0S6xWaQvWpJow} -j RETURN",
      "{FORWARD} -o testif -p tcp -s 1.1.1.1/32 -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j GcN7oXzN0S6xWaQvWpJow",
      "{FORWARD} -o testif -p icmp -s 1.1.1.1/32 -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j GcN7oXzN0S6xWaQvWpJow",
      "{fRRuJfK6pBu0deeVX08Hyg} -s 7.7.7.7/32 -j RETURN",
      "{fRRuJfK6pBu0deeVX08Hyg} -s 8.8.8.8/32 -j RETURN",
      "{fRRuJfK6pBu0deeVX08Hyg} -j ACCEPT",
      "{FORWARD} -i testif -p tcp ! -d 9.9.9.9/32 -m conntrack --ctstate RELATED,ESTABLISHED -m multiport --sports 22 -j fRRuJfK6pBu0deeVX08Hyg",
      "{FORWARD} -i testif -p icmp ! -d 9.9.9.9/32 -m conntrack --ctstate RELATED,ESTABLISHED -m icmp --icmp-type 0/0 -j fRRuJfK6pBu0deeVX08Hyg",
      "{KCAXNiU0DNpRX0b4v7gg} -d 7.7.7.7/32 -j RETURN",
      "{KCAXNiU0DNpRX0b4v7gg} -d 8.8.8.8/32 -j RETURN",
      "{KCAXNiU0DNpRX0b4v7gg} -j ACCEPT",
      "{FORWARD} -o testif -p tcp ! -s 9.9.9.9/32 -m conntrack --ctstate NEW,ESTABLISHED -m multiport --dports 22 -j KCAXNiU0DNpRX0b4v7gg",
      "{FORWARD} -o testif -p icmp ! -s 9.9.9.9/32 -m conntrack --ctstate NEW,ESTABLISHED -m icmp --icmp-type 8/0 -j KCAXNiU0DNpRX0b4v7gg"
    ], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
  end

  def test_host_1_lt_2
    fw = Construqt::Firewalls.add() do |fw|
      fw.host do |host|
        host.add.action(Construqt::Firewalls::Actions::ACCEPT).from_my_net.to_net("@224.0.0.18").request_only.from_is_inside
        host.add.action(Construqt::Firewalls::Actions::ACCEPT).from_my_net.to_net("@224.0.0.18").respond_only.from_is_inside
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_host(fw, fw.get_host, "testif", writer)
    assert_equal [
      "{XuMvsQ1X8uDScAdbGFTug} -d 5.5.5.0/24 -j ACCEPT",
      "{XuMvsQ1X8uDScAdbGFTug} -d 5.5.6.0/24 -j ACCEPT",
      "{XuMvsQ1X8uDScAdbGFTug} -j RETURN",
      "{INPUT} -i testif -s 224.0.0.18/32 -j XuMvsQ1X8uDScAdbGFTug",
      "{Fk3EKrBPaMT0svWooAAQ} -s 5.5.5.0/24 -j ACCEPT",
      "{Fk3EKrBPaMT0svWooAAQ} -s 5.5.6.0/24 -j ACCEPT",
      "{Fk3EKrBPaMT0svWooAAQ} -j RETURN",
      "{OUTPUT} -o testif -d 224.0.0.18/32 -j Fk3EKrBPaMT0svWooAAQ"
    ], writer.ipv4.rows
    assert_equal [], writer.ipv6.rows
  end

  def test_forward_1_1
    fw = Construqt::Firewalls.find('l-outbound').attach_iface(TEST_VRRP_IF.first)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "{FORWARD} -i testif -s 29::29:29:1/128 -d 2000::/3 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT",
      "{FORWARD} -o testif -s 2000::/3 -d 29::29:29:1/128 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT"
    ], writer.ipv6.rows
    assert_equal [
      "{FORWARD} -i testif -s 29.29.29.1/32 -d 0.0.0.0/0 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT",
      "{FORWARD} -o testif -s 0.0.0.0/0 -d 29.29.29.1/32 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT"
    ], writer.ipv4.rows
  end

  def test_forward_tcp_mss
    fw = Construqt::Firewalls.add("l-tcp-mss") do |fw|
      fw.forward do |forward|
        forward.add.action(Construqt::Firewalls::Actions::TCPMSS)
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
     "{FORWARD} -i testif -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu",
     "{FORWARD} -o testif -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu"
    ], writer.ipv6.rows
    assert_equal [
     "{FORWARD} -i testif -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu",
     "{FORWARD} -o testif -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu"
    ], writer.ipv4.rows
  end

  def test_forward_tcp_mss_value
    fw = Construqt::Firewalls.add("l-tcp-mss-value") do |fw|
      fw.forward do |forward|
        forward.add.action(Construqt::Firewalls::Actions::TCPMSS).mss(1220)
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
     "{FORWARD} -i testif -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1220",
     "{FORWARD} -o testif -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1220"
    ], writer.ipv4.rows
    assert_equal [
     "{FORWARD} -i testif -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1196",
     "{FORWARD} -o testif -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1196"
    ], writer.ipv6.rows
  end

  def test_filter_nets
    fw = Construqt::Firewalls.add("net-nat-filter") do |fw|
      fw.nat do |nat|
        nat.add.postrouting.action(Construqt::Firewalls::Actions::SNAT)
          .from_net("#TEST_FROM_FILTER").from_filter_local.to_source
          .to_net("#TEST_TO_FILTER").to_filter_local.to_source
          .from_is_inside
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_nat(fw, fw.get_nat, "testif", writer)
    assert_equal [
      "{POSTROUTING} -o testif -s 5.5.5.0/24 -j SNAT --to-source 5.5.5.5"
    ], writer.ipv4.rows
    assert_equal [
    ], writer.ipv6.rows

    fw = Construqt::Firewalls.add("net-nat") do |fw|
      fw.nat do |nat|
        nat.add.postrouting.action(Construqt::Firewalls::Actions::SNAT)
          .from_net("#TEST_FROM_FILTER").to_source
          .to_net("#TEST_TO_FILTER").to_source
          .from_is_inside
      end
    end.attach_iface(TEST_IF)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_nat(fw, fw.get_nat, "testif", writer)
    assert_equal [
      "{DVzkPxLgpwnzc369xausJQ} -s 1.1.1.0/24 -j SNAT --to-source 5.5.5.5",
      "{DVzkPxLgpwnzc369xausJQ} -s 5.5.5.0/24 -j SNAT --to-source 5.5.5.5",
      "{DVzkPxLgpwnzc369xausJQ} -j RETURN",
      "{TNcOyV76ZrilSl1qw6l4A} -d 2.2.2.0/24 -j DVzkPxLgpwnzc369xausJQ",
      "{TNcOyV76ZrilSl1qw6l4A} -d 4.4.4.0/24 -j DVzkPxLgpwnzc369xausJQ",
      "{TNcOyV76ZrilSl1qw6l4A} -j RETURN",
      "{POSTROUTING} -o testif -j TNcOyV76ZrilSl1qw6l4A"
    ], writer.ipv4.rows
    assert_equal [
    ], writer.ipv6.rows
  end

  def test_dynamic_ip_and_snat
    fw = Construqt::Firewalls.add("dhcp-net-nat") do |fw|
      fw.nat do |nat|
        nat.add.postrouting.action(Construqt::Firewalls::Actions::SNAT)
          .from_net("#TEST_FROM_FILTER").to_source.from_is_inside
      end
    end.attach_iface(DHCP_IF)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_nat(fw, fw.get_nat, "dhcpif", writer)
    assert_equal [
      "{POSTROUTING} -o dhcpif -s 1.1.1.0/24 -j MASQUERADE",
      "{POSTROUTING} -o dhcpif -s 5.5.5.0/24 -j MASQUERADE"
    ], writer.ipv4.rows
    assert_equal [
    ], writer.ipv6.rows

    fw = Construqt::Firewalls.add("dhcp-global-nat") do |fw|
      fw.nat do |nat|
        nat.add.postrouting.action(Construqt::Firewalls::Actions::SNAT).to_source.from_is_inside
      end
    end.attach_iface(DHCP_IF)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_nat(fw, fw.get_nat, "dhcpif", writer)
    assert_equal [
      "{POSTROUTING} -o dhcpif -j MASQUERADE"
    ], writer.ipv4.rows
    assert_equal [
    ], writer.ipv6.rows
  end

  def test_dynamic_ip_and_from_my_net_forward
    fw = Construqt::Firewalls.find('l-outbound').attach_iface(DHCP_IF)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_forward(fw, fw.get_forward, "testif", writer)
    assert_equal [
      "BLA"
    ], writer.ipv4.rows
    assert_equal [
      "BLA"
    ], writer.ipv6.rows
  end

  def test_dynamic_ip_and_from_my_net_host
    fw = Construqt::Firewalls.find('l-outbound-host').attach_iface(DHCP_IF)
    writer = TestWriter.new
    Construqt::Flavour::Nixian::Dialect::Ubuntu::Firewall.write_host(fw, fw.get_host, "testif", writer)
    assert_equal [
      "BLA"
    ], writer.ipv4.rows
    assert_equal [
      "BLA"
    ], writer.ipv6.rows

  end


end

#result = RubyProf.stop
#printer = RubyProf::FlatPrinter.new(result)
#printer.print(STDOUT)
