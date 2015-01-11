

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

  def setup
    @rule = Construqt::Firewalls::Firewall::Forward::ForwardEntry.new
    @rule.attached_interface = TEST_IF
  end

  def test_from_list_v4_from_net_iface_network
    family = Construqt::Addresses::IPV4
    assert_nets [], @rule.from_list(family)
    @rule.from_net
    assert_nets ["5.5.5.0/24", "5.5.6.0/24"], @rule.from_list(family)
    @rule.from_net.include_routes
    assert_nets ["5.5.5.0/24", "5.5.6.0/24", "11.11.11.0/24", "12.12.12.0/24"], @rule.from_list(family)
  end

  def test_from_list_v4_from_net_parameter
    family = Construqt::Addresses::IPV4
    assert_nets [], @rule.from_list(family)
    @rule.from_net("UNKNOWN_TAG")
    assert_nets [], @rule.from_list(family)
    @rule.from_net("FIRST_NET_1_TAG#FIRST_NET_2_TAG")
    assert_nets ["1.1.1.0/24"], @rule.from_list(family)
    @rule.from_net("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG")
    assert_nets ["1.1.1.0/24", "2.2.2.0/24"], @rule.from_list(family)
    @rule.from_net("@8.8.8.8/24")
    assert_nets ["8.8.8.0/24"], @rule.from_list(family)
    @rule.from_net("@8.8.8.8/24@8.8.4.4/24")
    assert_nets ["8.8.4.0/24","8.8.8.0/24"], @rule.from_list(family)
    @rule.from_net("@www.slashdot.org")
    assert_nets ["216.34.181.48/32"], @rule.from_list(family)
    @rule.from_net("@www.slashdot.org@heise.de")
    assert_nets ["193.99.144.80/32", "216.34.181.48/32"], @rule.from_list(family)
    @rule.from_net("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG@www.slashdot.org@heise.de@8.8.8.8/24@8.8.4.4/24")
    assert_nets ["1.1.1.0/24", "2.2.2.0/24", "8.8.4.0/24", "8.8.8.0/24", "193.99.144.80/32", "216.34.181.48/32"], @rule.from_list(family)
    @rule.from_net("TEST")
    assert_nets ["1.1.1.0/24", "2.2.2.0/24"], @rule.from_list(family)
  end

  def test_from_list_v4_from_host_iface_network
    family = Construqt::Addresses::IPV4
    assert_nets [], @rule.from_list(family)
    @rule.from_host
    assert_nets ["5.5.5.5/32", "5.5.5.6/32", "5.5.6.5/32", "5.5.6.6/32"], @rule.from_list(family)
    @rule.from_host.include_routes
    assert_nets ["5.5.5.5/32",
                 "5.5.5.6/32",
                 "5.5.6.5/32",
                 "5.5.6.6/32",
                 "11.11.11.0/24",
                 "12.12.12.0/24"], @rule.from_list(family)
  end

  def test_from_list_v4_from_host_parameter
    family = Construqt::Addresses::IPV4
    assert_nets [], @rule.from_list(family)
    @rule.from_host("UNKNOWN_TAG")
    assert_nets [], @rule.from_list(family)
    @rule.from_host("FIRST_NET_1_TAG#FIRST_NET_2_TAG")
    assert_nets ["1.1.1.1/32", "1.1.1.2/32"], @rule.from_list(family)
    @rule.from_host("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG")
    assert_nets ["1.1.1.1/32", "1.1.1.2/32", "2.2.2.2/31"], @rule.from_list(family)
    @rule.from_host("@8.8.8.8/24")
    assert_nets ["8.8.8.8/32"], @rule.from_list(family)
    @rule.from_host("@8.8.8.8/24@8.8.4.4/24")
    assert_nets ["8.8.4.4/32","8.8.8.8/32"], @rule.from_list(family)
    @rule.from_host("@www.slashdot.org")
    assert_nets ["216.34.181.48/32"], @rule.from_list(family)
    @rule.from_host("@www.slashdot.org@heise.de")
    assert_nets ["193.99.144.80/32", "216.34.181.48/32"], @rule.from_list(family)
    @rule.from_host("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG@www.slashdot.org@heise.de@8.8.8.8/24@8.8.4.4/24")
    assert_nets ["1.1.1.1/32", "1.1.1.2/32", "2.2.2.2/31", "8.8.4.4/32", "8.8.8.8/32", "193.99.144.80/32", "216.34.181.48/32"], @rule.from_list(family)
    @rule.from_host("TEST")
    assert_nets ["1.1.1.1/32", "1.1.1.2/32", "2.2.2.2/31"], @rule.from_list(family)
  end

  def test_from_list_v6_from_net_iface_network
    family = Construqt::Addresses::IPV6
    assert_nets [], @rule.from_list(family)
    @rule.from_net
    assert_nets ["5::5:5:0/124", "5::5:6:0/124"], @rule.from_list(family)
    @rule.from_net.include_routes
    assert_nets ["5::5:5:0/124", "5::5:6:0/124", "11::11:11:0/124", "12::12:12:0/124"], @rule.from_list(family)
  end

  def test_from_list_v6_from_net_parameter
    family = Construqt::Addresses::IPV6
    assert_nets [], @rule.from_list(family)
    @rule.from_net("UNKNOWN_TAG")
    assert_nets [], @rule.from_list(family)
    @rule.from_net("FIRST_NET_1_TAG#FIRST_NET_2_TAG")
    assert_nets ["1::1:1:0/124"], @rule.from_list(family)
    @rule.from_net("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG")
    assert_nets ["1::1:1:0/124", "2::2:2:0/124"], @rule.from_list(family)
    @rule.from_net("@8::8:8:8/124")
    assert_nets ["8::8:8:0/124"], @rule.from_list(family)
    @rule.from_net("@8::8:8:8/124@8::8:4:4/124")
    assert_nets ["8::8:4:0/124","8::8:8:0/124"], @rule.from_list(family)
    @rule.from_net("@google-public-dns-a.google.com")
    assert_nets ["2001:4860:4860::8888/128"], @rule.from_list(family)
    @rule.from_net("@google-public-dns-a.google.com@google-public-dns-b.google.com")
    assert_nets ["2001:4860:4860::8844/128", "2001:4860:4860::8888/128"], @rule.from_list(family)
    @rule.from_net("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG@google-public-dns-a.google.com@google-public-dns-b.google.com@8::8:8:8/124@8::8:4:4/124")
    assert_nets ["1::1:1:0/124", "2::2:2:0/124", "8::8:4:0/124", "8::8:8:0/124", "2001:4860:4860::8844/128", "2001:4860:4860::8888/128"], @rule.from_list(family)
    @rule.from_net("TEST")
    assert_nets ["1::1:1:0/124", "2::2:2:0/124"], @rule.from_list(family)
  end

  def test_from_list_v6_from_host_iface_network
    family = Construqt::Addresses::IPV6
    assert_nets [], @rule.from_list(family)
    @rule.from_host
    assert_nets ["5::5:5:5/128", "5::5:5:6/128", "5::5:6:5/128", "5::5:6:6/128"], @rule.from_list(family)
    @rule.from_host.include_routes
    assert_nets ["5::5:5:5/128",
                 "5::5:5:6/128",
                 "5::5:6:5/128",
                 "5::5:6:6/128",
                 "11::11:11:0/124",
                 "12::12:12:0/124"], @rule.from_list(family)
  end

  def test_from_list_v6_from_host_parameter
    family = Construqt::Addresses::IPV6
    assert_nets [], @rule.from_list(family)
    @rule.from_host("UNKNOWN_TAG")
    assert_nets [], @rule.from_list(family)
    @rule.from_host("FIRST_NET_1_TAG#FIRST_NET_2_TAG")
    assert_nets ["1::1:1:1/128", "1::1:1:2/128"], @rule.from_list(family)
    @rule.from_host("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAG")
    assert_nets ["1::1:1:1/128", "1::1:1:2/128", "2::2:2:2/127"], @rule.from_list(family)
    @rule.from_host("@8::8:8:8/124")
    assert_nets ["8::8:8:8/128"], @rule.from_list(family)
    @rule.from_host("@8::8:8:8/124@8::8:4:4/124")
    assert_nets ["8::8:4:4/128","8::8:8:8/128"], @rule.from_list(family)
    @rule.from_host("@google-public-dns-a.google.com")
    assert_nets ["2001:4860:4860::8888/128"], @rule.from_list(family)
    @rule.from_host("@google-public-dns-a.google.com@google-public-dns-b.google.com")
    assert_nets ["2001:4860:4860::8844/128", "2001:4860:4860::8888/128"], @rule.from_list(family)
    @rule.from_host("FIRST_NET_1_TAG#FIRST_NET_2_TAG#SECOND_NET_1_TAG#SECOND_NET_2_TAGgoogle-public-dns-a.google.com@google-public-dns-a.google.com@8::8:8:8/124@8::8:4:4/124")
    assert_nets ["1::1:1:1/128", "1::1:1:2/128", "2::2:2:2/128", "8::8:4:4/128", "8::8:8:8/128", "2001:4860:4860::8888/128"], @rule.from_list(family)
    @rule.from_host("TEST")
    assert_nets ["1::1:1:1/128", "1::1:1:2/128", "2::2:2:2/127"], @rule.from_list(family)
  end

  def test_from_list_v6_me
    family = Construqt::Addresses::IPV6
    assert_nets [], @rule.from_list(family)
    @rule.from_me
    assert_nets ["5::5:5:5/128", "5::5:5:6/128", "5::5:6:5/128", "5::5:6:6/128"], @rule.from_list(family)
    @rule.from_net("TEST")
    assert_nets ["1::1:1:0/124", "2::2:2:0/124", "5::5:5:5/128", "5::5:5:6/128", "5::5:6:5/128", "5::5:6:6/128"], @rule.from_list(family)
    @rule.from_me.include_routes
    assert_nets ["1::1:1:0/124",
                 "2::2:2:0/124",
                 "5::5:5:5/128",
                 "5::5:5:6/128",
                 "5::5:6:5/128",
                 "5::5:6:6/128",
                 "11::11:11:0/124",
                 "12::12:12:0/124"], @rule.from_list(family)
  end

  def test_from_list_v4_me
    family = Construqt::Addresses::IPV4
    assert_nets [], @rule.from_list(family)
    @rule.from_me
    assert_nets ["5.5.5.5/32", "5.5.5.6/32", "5.5.6.5/32", "5.5.6.6/32"], @rule.from_list(family)
    @rule.from_net("TEST")
    assert_nets ["1.1.1.0/24", "2.2.2.0/24", "5.5.5.5/32", "5.5.5.6/32", "5.5.6.5/32", "5.5.6.6/32"], @rule.from_list(family)
    @rule.from_me.include_routes
    assert_nets ["1.1.1.0/24",
                 "2.2.2.0/24",
                 "5.5.5.5/32",
                 "5.5.5.6/32",
                 "5.5.6.5/32",
                 "5.5.6.6/32",
                 "11.11.11.0/24",
                 "12.12.12.0/24"], @rule.from_list(family)
  end

  def test_from_list_v6_my_net
    family = Construqt::Addresses::IPV6
    assert_nets [], @rule.from_list(family)
    @rule.from_my_net
    assert_nets ["5::5:5:0/124", "5::5:6:0/124"], @rule.from_list(family)
    @rule.from_net("TEST")
    assert_nets ["1::1:1:0/124", "2::2:2:0/124", "5::5:5:0/124", "5::5:6:0/124"], @rule.from_list(family)
    @rule.from_my_net.include_routes
    assert_nets ["1::1:1:0/124", "2::2:2:0/124", "5::5:5:0/124", "5::5:6:0/124", "11::11:11:0/124", "12::12:12:0/124"], @rule.from_list(family)
  end

  def test_from_list_v4_my_net
    family = Construqt::Addresses::IPV4
    assert_nets [], @rule.from_list(family)
    @rule.from_my_net
    assert_nets ["5.5.5.0/24", "5.5.6.0/24"], @rule.from_list(family)
    @rule.from_net("TEST")
    assert_nets ["1.1.1.0/24", "2.2.2.0/24", "5.5.5.0/24", "5.5.6.0/24"], @rule.from_list(family)
    @rule.from_my_net.include_routes
    assert_nets ["1.1.1.0/24",
                 "2.2.2.0/24",
                 "5.5.5.0/24",
                 "5.5.6.0/24",
                 "11.11.11.0/24",
                 "12.12.12.0/24"], @rule.from_list(family)
  end
end
