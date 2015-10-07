

def firewall(region)

  Construqt::Firewalls.add("fix-mss") do |fw|
    fw.forward do |fwd|
      fwd.add.from_net("#SERVICE-NET-DE#SERVICE-NET-US#SERVICE-TRANSIT-DE#IPSECVPN-DE#IPSECVPN-US").mss(1280).action(Construqt::Firewalls::Actions::TCPMSS)
#      fwd.add.to_net("#SERVICE-NET#SERVICE-TRANSIT#IPSECVPN").mss(1380).action(Construqt::Firewalls::Actions::TCPMSS)
#  iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS  --clamp-mss-to-pmtu
    end
  end

  Construqt::Firewalls.add("vpn-server-net") do |fw|
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).from_net("#FANOUT-DE-BACKEND#IPSECVPN-DE#IPSECVPN-US").to_net("#SERVICE-NET-DE#SERVICE-NET-US#SERVICE-TRANSIT-DE").from_is_outside
    end
  end

  Construqt::Firewalls.add("service-nat") do |fw|
    fw.nat do |nat|
      nat.add.postrouting.action(Construqt::Firewalls::Actions::SNAT).from_net("#FANOUT-DE-BACKEND#SERVICE-NET-DE#SERVICE-TRANSIT-DE#IPSECVPN-DE").to_source.from_is_inside
      nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).from_net("#INTERNET").to_me.tcp.dport(25).dport(587).dport(465).to_dest("HOST-smtp-ng").from_is_outside
      nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).from_net("#INTERNET").to_me.tcp.dport(993).to_dest("HOST-imap-ng").from_is_outside
      nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).from_net("#INTERNET").to_me.udp.dport(53).to_dest("HOST-bind-ng").from_is_outside
      nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).from_net("#INTERNET").to_me.tcp.dport(53).to_dest("HOST-bind-ng").from_is_outside
    end
  end

  Construqt::Firewalls.add("service-us-nat") do |fw|
    fw.nat do |nat|
      nat.add.postrouting.action(Construqt::Firewalls::Actions::SNAT).from_net("#SERVICE-NET-US#SERVICE-TRANSIT-US#IPSECVPN-US").to_source.from_is_inside
      nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).from_net("#INTERNET").to_me.tcp.dport(25).dport(587).dport(465).to_dest("HOST-smtp-us").from_is_outside
      nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).from_net("#INTERNET").to_me.tcp.dport(993).to_dest("HOST-imap-us").from_is_outside
      nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).from_net("#INTERNET").to_me.udp.dport(53).to_dest("HOST-bind-us").from_is_outside
      nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).from_net("#INTERNET").to_me.tcp.dport(53).to_dest("HOST-bind-us").from_is_outside
    end
  end

  Construqt::Firewalls.add("service-smtp") do |fw|
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_host("HOST-smtp-ng").tcp.dport(25).dport(587).dport(465).from_is_outside
    end
  end

  Construqt::Firewalls.add("service-ssh-hgw") do |fw|
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv6.connection.from_net("#INTERNET").to_net("SERVICE-NET-DE-HGW").tcp.dport(22).from_is_outside
    end
  end

  Construqt::Firewalls.add("service-imap") do |fw|
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_host("HOST-imap-ng").tcp.dport(993).from_is_outside
    end
  end

  Construqt::Firewalls.add("service-ad") do |fw|
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).from_host("#HOST-ad-de").to_host("HOST-ad")
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).from_host("#HOST-ad-us").to_host("HOST-ad")
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).from_host("#HOST-ad-us").to_host("HOST-ad-de")
    end
  end

  Construqt::Firewalls.add("service-dns") do |fw|
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_host("HOST-bind-ng").udp.dport(53).from_is_outside
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_host("HOST-bind-ng").tcp.dport(53).from_is_outside
    end
  end

  Construqt::Firewalls.add("icmp-ping") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET")
        .to_my_net.icmp.type(Construqt::Firewalls::ICMP::Ping).from_is_outside
    end
    fw.forward do |forward|
      forward.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET")
        .to_net("#SERVICE-NET-DE#SERVICE-TRANSIT-DE#IPSECVPN-DE#IPSECVPN-US").icmp.type(Construqt::Firewalls::ICMP::Ping).from_is_outside
    end
  end

  Construqt::Firewalls.add("ssh-srv") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_me.tcp.dport(22).from_is_outside
    end
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_me.tcp.dport(22).from_is_outside
    end
  end

  Construqt::Firewalls.add("service-transit") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).from_net("#SERVICE-TRANSIT-DE#SERVICE-IPSEC#IPSECVPN-DE").to_net("#SERVICE-TRANSIT-DE#SERVICE-IPSEC#IPSECVPN-DE")
    end
  end

  Construqt::Firewalls.add("service-us-transit") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).from_net("#SERVICE-TRANSIT-US#SERVICE-IPSEC-US#IPSECVPN-US").to_net("#SERVICE-TRANSIT-US#SERVICE-IPSEC-US#IPSECVPN-US")
    end
  end

  Construqt::Firewalls.add("ipsec-srv") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_net("#INTERNET").to_my_net.udp.dport("isakmp")
        .dport("ipsec-nat-t").from_is_outside
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv4.from_net("#INTERNET").to_my_net.esp.from_is_outside
    end
  end

  Construqt::Firewalls.add("host-outbound") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_my_net.to_net("#INTERNET").from_is_inside
    end
    fw.forward do |forward|
      forward.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#FANOUT-DE-BACKEND#SERVICE-NET-DE#SERVICE-TRANSIT-DE#IPSECVPN-DE").to_net("#INTERNET").from_is_inside
    end
  end

  Construqt::Firewalls.add("host-us-outbound") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_my_net.to_net("#INTERNET").from_is_inside
    end
    fw.forward do |forward|
      forward.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#IPSECVPN-US#SERVICE-NET-US#SERVICE-TRANSIT-US").to_net("#INTERNET").from_is_inside
    end
  end

  Construqt::Firewalls.add("block") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).link_local.from_is_outside
      host.add.action(Construqt::Firewalls::Actions::DROP).log("HOST")
    end
    fw.forward do |forward|
      forward.add.action(Construqt::Firewalls::Actions::DROP).log("FORWARD")
    end
  end
end
