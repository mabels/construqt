

require 'test/unit'

#$LOAD_PATH.unshift(File.dirname(__FILE__))
#$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

CONSTRUQT_PATH=ENV['CONSTRUQT_PATH']||'.'
["#{CONSTRUQT_PATH}/construqt/lib","#{CONSTRUQT_PATH}/ipaddress/lib"].each{|path| $LOAD_PATH.unshift(path) }
require 'construqt'

network = Construqt::Networks.add('Construqt-Test-Network')
REGION = Construqt::Regions.add("Construqt-Test-Region", network)

REGION.network.addresses.tag("TEST")
  .add_ip("1.1.1.1/24#FIRST_NET_1_TAG")
  .add_ip("1.1.1.2/24#FIRST_NET_2_TAG")
  .add_ip("1::1:1:1/124#FIRST_NET_1_TAG")
  .add_ip("1::1:1:2/124#FIRST_NET_2_TAG")
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
                .begin_to("<begin_to>")
                .begin_from("<begin_from>")
                .middle_to("<middle_to>")
                .middle_from("<middle_from>")
                .end_to("<end_to>")
                .end_from("<end_from>")
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


  def test_write_table_from_list_empty_to_list_empty
    rule = create_rule
    to_from = create_to_from
    Construqt::Flavour::Ubuntu::Firewall.write_table(:test, rule, to_from)
    assert_equal [
      "{DEFAULT} <output_ifname_direction> <ifname> <begin_from> <middle_to> -j <action> <end_to>",
      "{DEFAULT} <input_ifname_direction> <ifname> <begin_to> <middle_from> -j <action> <end_from>"], to_from.get_factory.rows

    to_from = create_to_from
    to_from.input_only
    Construqt::Flavour::Ubuntu::Firewall.write_table(:test, rule, to_from)
    assert_equal ["{DEFAULT} <input_ifname_direction> <ifname> <begin_to> <middle_from> -j <action> <end_from>"], to_from.get_factory.rows

    to_from = create_to_from
    to_from.output_only
    Construqt::Flavour::Ubuntu::Firewall.write_table(:test, rule, to_from)
    assert_equal ["{DEFAULT} <output_ifname_direction> <ifname> <begin_from> <middle_to> -j <action> <end_to>"], to_from.get_factory.rows
  end

  def test_write_table_to_list_empty_from_list_length
    rule = create_rule
    to_from = create_to_from
    rule.from_net("@8.8.8.8/24")
    Construqt::Flavour::Ubuntu::Firewall.write_table(:test, rule, to_from)
    assert_equal [
      "{DEFAULT} <output_ifname_direction> <ifname> <begin_from> -s 8.8.8.0/24 <middle_from> -j <action> <end_to>",
      "{DEFAULT} <input_ifname_direction> <ifname> <begin_to> -d 8.8.8.0/24 <middle_to> -j <action> <end_from>"], to_from.get_factory.rows

    to_from = create_to_from
    to_from.input_only
    Construqt::Flavour::Ubuntu::Firewall.write_table(:test, rule, to_from)
    assert_equal ["{DEFAULT} <input_ifname_direction> <ifname> <begin_to> -d 8.8.8.0/24 <middle_to> -j <action> <end_from>"], to_from.get_factory.rows

    to_from = create_to_from
    to_from.output_only
    Construqt::Flavour::Ubuntu::Firewall.write_table(:test, rule, to_from)
    assert_equal ["{DEFAULT} <output_ifname_direction> <ifname> <begin_from> -s 8.8.8.0/24 <middle_from> -j <action> <end_to>"], to_from.get_factory.rows
  end

  def test_write_table_from_list_length_to_list_empty
    rule = create_rule
    to_from = create_to_from
    rule.to_net("@8.8.8.8/24")
    Construqt::Flavour::Ubuntu::Firewall.write_table(:test, rule, to_from)
    assert_equal [
      "{DEFAULT} <output_ifname_direction> <ifname> <begin_from> -s 8.8.8.0/24 <middle_from> -j <action> <end_to>",
      "{DEFAULT} <input_ifname_direction> <ifname> <begin_to> -d 8.8.8.0/24 <middle_to> -j <action> <end_from>"], to_from.get_factory.rows

    to_from = create_to_from
    to_from.input_only
    Construqt::Flavour::Ubuntu::Firewall.write_table(:test, rule, to_from)
    assert_equal ["{DEFAULT} <input_ifname_direction> <ifname> <begin_to> -d 8.8.8.0/24 <middle_to> -j <action> <end_from>"], to_from.get_factory.rows

    to_from = create_to_from
    to_from.output_only
    Construqt::Flavour::Ubuntu::Firewall.write_table(:test, rule, to_from)
    assert_equal ["{DEFAULT} <output_ifname_direction> <ifname> <begin_from> -s 8.8.8.0/24 <middle_from> -j <action> <end_to>"], to_from.get_factory.rows
  end

  def test_write_table_to_list_length_from_list_length_eq_1
    rule = create_rule
    to_from = create_to_from
    rule.from_net("@4.4.4.4/24")
    rule.to_net("@8.8.8.8/24")
    Construqt::Flavour::Ubuntu::Firewall.write_table(:test, rule, to_from)
    assert_equal [
      "{DEFAULT} <output_ifname_direction> <ifname> <begin_from> -s 4.4.4.0/24 -d 8.8.8.0/24 <middle_from> -j <action> <end_to>",
      "{DEFAULT} <input_ifname_direction> <ifname> <begin_to> -d 4.4.4.0/24 -s 8.8.8.0/24 <middle_to> -j <action> <end_from>"], to_from.get_factory.rows

    to_from = create_to_from
    to_from.input_only
    Construqt::Flavour::Ubuntu::Firewall.write_table(:test, rule, to_from)
    assert_equal ["{DEFAULT} <input_ifname_direction> <ifname> <begin_to> -d 4.4.4.0/24 -s 8.8.8.0/24 <middle_to> -j <action> <end_from>"], to_from.get_factory.rows

    to_from = create_to_from
    to_from.output_only
    Construqt::Flavour::Ubuntu::Firewall.write_table(:test, rule, to_from)
    assert_equal ["{DEFAULT} <output_ifname_direction> <ifname> <begin_from> -s 4.4.4.0/24 -d 8.8.8.0/24 <middle_from> -j <action> <end_to>"], to_from.get_factory.rows
  end

  def test_write_table_to_list_length_eq_from_list_length_gt_1
    rule = create_rule
    to_from = create_to_from
    rule.to_net("@8.8.8.8/24@9.9.9.9/24")
    rule.from_net("@4.4.4.4/24@5.5.5.5/24")
    Construqt::Flavour::Ubuntu::Firewall.write_table(:test, rule, to_from)
    assert_equal [
      "{RkebdEMYRffS9fWJ60Ktew} -d 8.8.8.0/24 -j <action> <end_from>",
      "{RkebdEMYRffS9fWJ60Ktew} -d 9.9.9.0/24 -j <action> <end_from>",
      "{DEFAULT} <output_ifname_direction> <ifname> <begin_from> -s 4.4.4.0/24 <middle_from> -j RkebdEMYRffS9fWJ60Ktew",
      "{zq8kiuDCXGktL57SbuI3zA} -s 8.8.8.0/24 -j <action> <end_to>",
      "{zq8kiuDCXGktL57SbuI3zA} -s 9.9.9.0/24 -j <action> <end_to>",
      "{DEFAULT} <input_ifname_direction> <ifname> <begin_to> -d 4.4.4.0/24 <middle_to> -j zq8kiuDCXGktL57SbuI3zA",
      "{DEFAULT} <output_ifname_direction> <ifname> <begin_from> -s 5.5.5.0/24 <middle_from> -j RkebdEMYRffS9fWJ60Ktew",
      "{DEFAULT} <input_ifname_direction> <ifname> <begin_to> -d 5.5.5.0/24 <middle_to> -j zq8kiuDCXGktL57SbuI3zA"], to_from.get_factory.rows

    to_from = create_to_from
    to_from.input_only
    Construqt::Flavour::Ubuntu::Firewall.write_table(:test, rule, to_from)
    assert_equal [
      "{zq8kiuDCXGktL57SbuI3zA} -s 8.8.8.0/24 -j <action> <end_to>",
      "{zq8kiuDCXGktL57SbuI3zA} -s 9.9.9.0/24 -j <action> <end_to>",
      "{DEFAULT} <input_ifname_direction> <ifname> <begin_to> -d 4.4.4.0/24 <middle_to> -j zq8kiuDCXGktL57SbuI3zA",
      "{DEFAULT} <input_ifname_direction> <ifname> <begin_to> -d 5.5.5.0/24 <middle_to> -j zq8kiuDCXGktL57SbuI3zA"], to_from.get_factory.rows

    to_from = create_to_from
    to_from.output_only
    Construqt::Flavour::Ubuntu::Firewall.write_table(:test, rule, to_from)
    assert_equal [
      "{RkebdEMYRffS9fWJ60Ktew} -d 8.8.8.0/24 -j <action> <end_from>",
      "{RkebdEMYRffS9fWJ60Ktew} -d 9.9.9.0/24 -j <action> <end_from>",
      "{DEFAULT} <output_ifname_direction> <ifname> <begin_from> -s 4.4.4.0/24 <middle_from> -j RkebdEMYRffS9fWJ60Ktew",
      "{DEFAULT} <output_ifname_direction> <ifname> <begin_from> -s 5.5.5.0/24 <middle_from> -j RkebdEMYRffS9fWJ60Ktew"], to_from.get_factory.rows
  end

  def test_write_table_to_list_length_le_from_list_length
    rule = create_rule
    to_from = create_to_from
    rule.to_net("@8.8.8.8/24@9.9.9.9/24")
    rule.from_net("@4.4.4.4/24@5.5.5.5/24@6.6.6.6/24")
    Construqt::Flavour::Ubuntu::Firewall.write_table(:test, rule, to_from)
    assert_equal [
      "{fcQmxBIDNRkMepTDLq9w} -s 8.8.8.0/24 -j <action> <end_from>",
      "{fcQmxBIDNRkMepTDLq9w} -s 9.9.9.0/24 -j <action> <end_from>",
      "{DEFAULT} <output_ifname_direction> <ifname> <begin_from> -d 8.8.8.0/24 <middle_from> -j fcQmxBIDNRkMepTDLq9w",
      "{09pFx0CgMcquavOKQ9p5Vg} -d 8.8.8.0/24 -j <action> <end_to>",
      "{09pFx0CgMcquavOKQ9p5Vg} -d 9.9.9.0/24 -j <action> <end_to>",
      "{DEFAULT} <input_ifname_direction> <ifname> <begin_to> -s 8.8.8.0/24 <middle_to> -j 09pFx0CgMcquavOKQ9p5Vg",
      "{DEFAULT} <output_ifname_direction> <ifname> <begin_from> -d 9.9.9.0/24 <middle_from> -j fcQmxBIDNRkMepTDLq9w",
      "{DEFAULT} <input_ifname_direction> <ifname> <begin_to> -s 9.9.9.0/24 <middle_to> -j 09pFx0CgMcquavOKQ9p5Vg"], to_from.get_factory.rows

    to_from = create_to_from
    to_from.input_only
    Construqt::Flavour::Ubuntu::Firewall.write_table(:test, rule, to_from)
    assert_equal [
      "{09pFx0CgMcquavOKQ9p5Vg} -d 8.8.8.0/24 -j <action> <end_to>",
      "{09pFx0CgMcquavOKQ9p5Vg} -d 9.9.9.0/24 -j <action> <end_to>",
      "{DEFAULT} <input_ifname_direction> <ifname> <begin_to> -s 8.8.8.0/24 <middle_to> -j 09pFx0CgMcquavOKQ9p5Vg",
      "{DEFAULT} <input_ifname_direction> <ifname> <begin_to> -s 9.9.9.0/24 <middle_to> -j 09pFx0CgMcquavOKQ9p5Vg"], to_from.get_factory.rows

    to_from = create_to_from
    to_from.output_only
    Construqt::Flavour::Ubuntu::Firewall.write_table(:test, rule, to_from)
    assert_equal [
      "{fcQmxBIDNRkMepTDLq9w} -s 8.8.8.0/24 -j <action> <end_from>",
      "{fcQmxBIDNRkMepTDLq9w} -s 9.9.9.0/24 -j <action> <end_from>",
      "{DEFAULT} <output_ifname_direction> <ifname> <begin_from> -d 8.8.8.0/24 <middle_from> -j fcQmxBIDNRkMepTDLq9w",
      "{DEFAULT} <output_ifname_direction> <ifname> <begin_from> -d 9.9.9.0/24 <middle_from> -j fcQmxBIDNRkMepTDLq9w"], to_from.get_factory.rows
  end

  def test_write_table_from_list_length_lt_to_list_length
    rule = create_rule
    to_from = create_to_from
    rule.to_net("@8.8.8.8/24@9.9.9.9/24@10.10.10.10/24")
    rule.from_net("@4.4.4.4/24@5.5.5.5/24")
    Construqt::Flavour::Ubuntu::Firewall.write_table(:test, rule, to_from)
    assert_equal [
      "{SkIy2M659Vjy0wXscuvsQ} -d 8.8.8.0/24 -j <action> <end_from>",
      "{SkIy2M659Vjy0wXscuvsQ} -d 9.9.9.0/24 -j <action> <end_from>",
      "{SkIy2M659Vjy0wXscuvsQ} -d 10.10.10.0/24 -j <action> <end_from>",
      "{DEFAULT} <output_ifname_direction> <ifname> <begin_from> -s 4.4.4.0/24 <middle_from> -j SkIy2M659Vjy0wXscuvsQ",
      "{E46MJC8uMQD32fMOhjmIpA} -s 8.8.8.0/24 -j <action> <end_to>",
      "{E46MJC8uMQD32fMOhjmIpA} -s 9.9.9.0/24 -j <action> <end_to>",
      "{E46MJC8uMQD32fMOhjmIpA} -s 10.10.10.0/24 -j <action> <end_to>",
      "{DEFAULT} <input_ifname_direction> <ifname> <begin_to> -d 4.4.4.0/24 <middle_to> -j E46MJC8uMQD32fMOhjmIpA",
      "{DEFAULT} <output_ifname_direction> <ifname> <begin_from> -s 5.5.5.0/24 <middle_from> -j SkIy2M659Vjy0wXscuvsQ",
      "{DEFAULT} <input_ifname_direction> <ifname> <begin_to> -d 5.5.5.0/24 <middle_to> -j E46MJC8uMQD32fMOhjmIpA"], to_from.get_factory.rows

    to_from = create_to_from
    to_from.input_only
    Construqt::Flavour::Ubuntu::Firewall.write_table(:test, rule, to_from)
    assert_equal [
      "{E46MJC8uMQD32fMOhjmIpA} -s 8.8.8.0/24 -j <action> <end_to>",
      "{E46MJC8uMQD32fMOhjmIpA} -s 9.9.9.0/24 -j <action> <end_to>",
      "{E46MJC8uMQD32fMOhjmIpA} -s 10.10.10.0/24 -j <action> <end_to>",
      "{DEFAULT} <input_ifname_direction> <ifname> <begin_to> -d 4.4.4.0/24 <middle_to> -j E46MJC8uMQD32fMOhjmIpA",
      "{DEFAULT} <input_ifname_direction> <ifname> <begin_to> -d 5.5.5.0/24 <middle_to> -j E46MJC8uMQD32fMOhjmIpA"], to_from.get_factory.rows

    to_from = create_to_from
    to_from.output_only
    Construqt::Flavour::Ubuntu::Firewall.write_table(:test, rule, to_from)
    assert_equal [
      "{SkIy2M659Vjy0wXscuvsQ} -d 8.8.8.0/24 -j <action> <end_from>",
      "{SkIy2M659Vjy0wXscuvsQ} -d 9.9.9.0/24 -j <action> <end_from>",
      "{SkIy2M659Vjy0wXscuvsQ} -d 10.10.10.0/24 -j <action> <end_from>",
      "{DEFAULT} <output_ifname_direction> <ifname> <begin_from> -s 4.4.4.0/24 <middle_from> -j SkIy2M659Vjy0wXscuvsQ",
      "{DEFAULT} <output_ifname_direction> <ifname> <begin_from> -s 5.5.5.0/24 <middle_from> -j SkIy2M659Vjy0wXscuvsQ"], to_from.get_factory.rows
  end


end
