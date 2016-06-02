

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
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).from_net("#FANOUT-DE-BACKEND#FANOUT-US-BACKEND#IPSECVPN-DE#IPSECVPN-US").to_net("#SERVICE-NET-DE#SERVICE-NET-US#SERVICE-TRANSIT-DE").from_is_outside
    end
  end

  Construqt::Firewalls.add("border-forward") do |fw|
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_is_inside
    end
  end
  Construqt::Firewalls.add("border-masq") do |fw|
    fw.nat do |nat|
      nat.add.postrouting.action(Construqt::Firewalls::Actions::SNAT).to_source.from_is_inside
    end
  end


  Construqt::Firewalls.add("net-nat") do |fw|
    fw.nat do |nat|
      nat.add.postrouting.action(Construqt::Firewalls::Actions::SNAT).from_net("#INTERNAL-NET").from_filter_local.to_source.from_is_inside
    end
  end

  Construqt::Firewalls.add("net-forward") do |fw|
    fw.forward do |fordward|
      fordward.add.action(Construqt::Firewalls::Actions::ACCEPT).from_net("#INTERNAL-NET").connection.from_filter_local.from_is_inside
    end

    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_my_net.to_net("#INTERNET").from_is_inside
    end
  end

  Construqt::Firewalls.add("service-nat") do |fw|
    fw.nat do |nat|
      nat.add.postrouting.action(Construqt::Firewalls::Actions::SNAT).from_net("#FANOUT-DE-BACKEND#SERVICE-NET-DE#SERVICE-TRANSIT-DE#IPSECVPN-DE").to_source.from_is_inside
      nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).from_net("#INTERNET").to_me.tcp.dport(25).dport(587).dport(465).to_dest("HOST-smtp-de").from_is_outside
      nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).from_net("#INTERNET").to_me.tcp.dport(993).to_dest("HOST-imap-de").from_is_outside
      nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).from_net("#INTERNET").to_me.udp.dport(53).to_dest("HOST-bind-de").from_is_outside
      nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).from_net("#INTERNET").to_me.tcp.dport(53).to_dest("HOST-bind-de").from_is_outside
      nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).from_net("#INTERNET").to_me.tcp.udp.dport(1194).dport(443).to_dest("HOST-ovpn", 1194).from_is_outside
    end
  end

  Construqt::Firewalls.add("service-us-nat") do |fw|
    fw.nat do |nat|
      nat.add.postrouting.action(Construqt::Firewalls::Actions::SNAT).from_net("#FANOUT-US-BACKEND#SERVICE-NET-US#SERVICE-TRANSIT-US#IPSECVPN-US").to_source.from_is_inside
      nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).from_net("#INTERNET").to_me.tcp.dport(25).dport(587).dport(465).to_dest("HOST-smtp-us").from_is_outside
      nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).from_net("#INTERNET").to_me.tcp.dport(993).to_dest("HOST-imap-us").from_is_outside
      nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).from_net("#INTERNET").to_me.udp.dport(53).to_dest("HOST-bind-us").from_is_outside
      nat.add.prerouting.action(Construqt::Firewalls::Actions::DNAT).from_net("#INTERNET").to_me.tcp.dport(53).to_dest("HOST-bind-us").from_is_outside
    end
  end

  Construqt::Firewalls.add("wl-printer") do |fw|
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection
        .from_net("#WL-PRINTABLE-NET#WL-PRINTABLE-BACKBONE")
        .to_net("#WL-PRINTABLE-NET").to_filter_local.tcp.dport(9100).dport(515).dport(631).from_is_outside

      #      fwd.add.action(Construqt::Firewalls::Actions::DROP)
      #        .from_net("#WL-PRINTABLE-NET").from_filter_local.to_net("#INTERNET").from_is_inside
    end
  end

  Construqt::Firewalls.add("service-smtp") do |fw|
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_host("HOST-smtp-de").tcp.dport(25).dport(587).dport(465).from_is_outside
    end
  end

  Construqt::Firewalls.add("service-imap") do |fw|
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_host("HOST-imap-de").tcp.dport(993).from_is_outside
    end
  end

  Construqt::Firewalls.add("service-ovpn") do |fw|
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_host("HOST-ovpn").tcp.dport(1194).from_is_outside
    end
  end

  Construqt::Firewalls.add("service-dns") do |fw|
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_host("HOST-bind-de").udp.dport(53).from_is_outside
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_host("HOST-bind-de").tcp.dport(53).from_is_outside
    end
  end

  Construqt::Firewalls.add("service-us-smtp") do |fw|
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_host("HOST-smtp-us").tcp.dport(25).dport(587).dport(465).from_is_outside
    end
  end

  Construqt::Firewalls.add("service-us-dns") do |fw|
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_host("HOST-bind-us").udp.dport(53).from_is_outside
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_host("HOST-bind-us").tcp.dport(53).from_is_outside
    end
  end

  Construqt::Firewalls.add("service-ssh-hgw") do |fw|
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).ipv6.connection.from_net("#INTERNET").to_net("SERVICE-NET-DE-HGW").tcp.dport(22).from_is_outside
    end
  end

  Construqt::Firewalls.add("service-ad") do |fw|
    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).from_host("#HOST-ad-de").to_host("HOST-ad")
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).from_host("#HOST-ad-us").to_host("HOST-ad")
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).from_host("#HOST-ad-us").to_host("HOST-ad-de")
    end
  end

  Construqt::Firewalls.add("icmp-ping") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET")
        .to_my_net.icmp.type(Construqt::Firewalls::ICMP::Ping).from_is_outside
    end

    fw.forward do |forward|
      forward.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET")
        .to_net("#SERVICE-NET-DE#SERVICE-TRANSIT-DE#IPSECVPN-DE#IPSECVPN-US#INTERNAL-NET").to_filter_local.icmp.type(Construqt::Firewalls::ICMP::Ping).from_is_outside
    end
  end

  Construqt::Firewalls.add("ssh-srv") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_me.tcp.dport(22).from_is_outside
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_me.udp.dport_range(60000,60100).from_is_outside
    end

    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_me.tcp.dport(22).from_is_outside
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_me.udp.dport_range(60000,60100).from_is_outside
    end
  end

  Construqt::Firewalls.add("http-srv") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_me.tcp.dport(80).dport(443).from_is_outside
    end

    fw.forward do |fwd|
      fwd.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#INTERNET").to_me.tcp.dport(80).dport(443).from_is_outside
    end
  end

  Construqt::Firewalls.add("service-transit") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).from_net("#SERVICE-TRANSIT-DE#SERVICE-IPSEC#IPSECVPN-DE").to_net("#SERVICE-TRANSIT-DE#SERVICE-IPSEC#IPSECVPN-DE")
    end
  end

  Construqt::Firewalls.add("service-transit-local") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT)
        .from_net("#SERVICE-TRANSIT-DE#SERVICE-IPSEC#IPSECVPN-DE").from_filter_local
        .to_net("#SERVICE-TRANSIT-DE#SERVICE-IPSEC#IPSECVPN-DE").to_filter_local
    end
  end

  Construqt::Firewalls.add("service-us-transit") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT)
        .from_net("#SERVICE-TRANSIT-US#SERVICE-IPSEC-US#IPSECVPN-US").from_filter_local
        .to_net("#SERVICE-TRANSIT-US#SERVICE-IPSEC-US#IPSECVPN-US").to_filter_local
    end
  end

  Construqt::Firewalls.add("ipsec-srv") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).from_net("#INTERNET").to_my_net.udp.dport("isakmp")
        .dport("ipsec-nat-t").from_is_outside
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).from_net("#INTERNET").to_my_net.esp.from_is_outside
    end
  end
  Construqt::Firewalls.add("host-outbound-simple") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_my_net.to_net("#INTERNET").from_is_inside
    end
  end

  Construqt::Firewalls.add("host-outbound") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_my_net.to_net("#INTERNET").from_is_inside
    end

    fw.forward do |forward|
      forward.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#FANOUT-DE-BACKEND#SERVICE-NET-DE#SERVICE-TRANSIT-DE#IPSECVPN-DE#INTERNAL-NET").to_net("#INTERNET").from_is_inside
    end
  end

  Construqt::Firewalls.add("host-us-outbound") do |fw|
    fw.host do |host|
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#SERVICE-IPSEC-US").to_net("#SERVICE-IPSEC-US").from_is_inside
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_my_net.to_net("#INTERNET").from_is_inside
    end

    fw.forward do |forward|
      forward.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("#FANOUT-US-BACKEND#SERVICE-IPSEC-US#IPSECVPN-US#SERVICE-NET-US#SERVICE-TRANSIT-US").to_net("#INTERNET").from_is_inside
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

  Construqt::Firewalls.add("fw-outbound") do |fw|
    fw.forward do |forward|
      forward.ipv6
      forward.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("@2000::/3").to_host("@2001:6f8:900:82bf:192:168:67:2").tcp.dport(22)
      forward.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_my_net.to_net("DEFAULT").from_is_outside
      forward.add.action(Construqt::Firewalls::Actions::DROP).log("FORWARD")
    end

    fw.host do |host|
      host.ipv6
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).link_local
      host.add.action(Construqt::Firewalls::Actions::DROP).log('HOST')
    end
  end

  Construqt::Firewalls.add("fw-sixxs") do |fw|
    fw.forward do |forward|
      forward.ipv6
      forward.add.action(Construqt::Firewalls::Actions::TCPMSS)
    end

    fw.host do |host|
      host.ipv6
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("@2000::/3").to_me.tcp.dport(22).from_is_outside
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_net("@2000::/3").to_me.icmp.type(Construqt::Firewalls::ICMP::Ping).from_is_outside
      host.add.action(Construqt::Firewalls::Actions::ACCEPT).connection.from_me.to_net("@2000::/3")
      host.add.action(Construqt::Firewalls::Actions::DROP).log('HOST')
    end
  end
end
