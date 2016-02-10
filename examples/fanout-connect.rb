module FanoutConnect
  def self.run(region, left, right)
    Construqt::Ipsecs.connection("#{left.name}<=>#{right.name}",
                                 "password" => IPSEC_PASSWORD,
                                 "transport_family" => Construqt::Addresses::IPV4,
                                 "mtu_v4" => 1360,
                                 "mtu_v6" => 1360,
                                 "keyexchange" => "ikev2",
                                 "left" => {
                                   "my" => region.network.addresses.add_ip("169.254.222.1/30")
                                     .add_ip("169.254.222.5/30#FANOUT-IC-DE")
                                     .add_route_from_tags("#FANOUT-DE-BACKEND", "#FANOUT-IC-US"),
                                   "host" => right,
                                   "remote" => region.interfaces.find(right, "eth0").address,
                                   "auto" => "add",
                                   "sourceip" => true
                                 },
                                 "right" => {
                                   "my" => region.network.addresses.add_ip("169.254.222.2/30")
                                     .add_ip("169.254.222.6/30#FANOUT-IC-US")
                                     .add_route_from_tags("#FANOUT-US-BACKEND", "#FANOUT-IC-DE"),
                                   "host" => left,
                                   "remote" => region.interfaces.find(left, "eth0").address,
                                   "auto" => "add",
                                   "sourceip" => true
                                 }
                                )
  end
end
