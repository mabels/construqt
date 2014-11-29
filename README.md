construqt
=========

Construqt Complex Routerconfiguration for a LIR-Setup

There is no documentation or anything helpful. I'm currently focus on an implementation so everything is changing.

We should be able to build these new kind of infrastructure.

https://docs.google.com/drawings/d/1Sfn1awwFOZOfG7t2gr9TTxfLPNIdftKWdfCulhHOKGc/edit?usp=sharing

```
  [1,2].each do |ct|
    Construqt::Hosts.add("muc-r#{"%02d"%ct}",
      "flavour" => "ubuntu", "users" => Construqt::Users.users) do |router|

        Construqt::Interfaces.add_device(router, "v891", "mtu" => "1500", :description=>"transit")
        Construqt::Interfaces.add_device(router, "v892", "mtu" => "1500", :description=>"office-net",
    "priority" => 100+ct,
    "address" => Construqt::Addresses.add_ip("192.16.90.1#{ct}/24").
                                                  add_ip("2000:dead:beaf:8922::1:#{ct}/64"))

        Construqt::Interfaces.add_device(router, "v120", "mtu" => "1500", :description=>"guest-net",
    "priority" => 100+ct,
    "address" => Construqt::Addresses.add_ip("192.168.89.1#{ct}/24").
                                                  add_ip("2000:dead:beaf:8912::1:#{ct}/64"))

        router.id = Construqt::Hosts::HostId.create do |my|
    my.interfaces << Construqt::Interfaces.add_device(router, "v893", "mtu" => "1500", :description=>"dmz",
        "address" => Construqt::Addresses.add_ip("1.2.148.#{34+ct}/29")
                       .add_route("0.0.0.0/0", "1.2.148.34")
                 .add_ip("2000:dead:beaf:8900:62:96:148:#{34+ct}/64")
                 .add_route("::/0", "2000:dead:beaf:8900::1"))
  end
  router.configip = router.id
    end
 end

  Construqt::Interfaces.add_vrrp("vrrp-muc-office",
                    "vrid" => 100,
                    "address" => Construqt::Addresses.add_ip("2000:dead:bead:8922::1/128").add_ip("192.16.90.10/32"),
                    "interfaces" => [
                      Construqt::Interfaces.find(Construqt::Hosts.find("muc-r01"), "v892"),
                      Construqt::Interfaces.find(Construqt::Hosts.find("muc-r02"), "v892")
                    ])
  Construqt::Interfaces.add_vrrp("vrrp-muc-guest",
                    "vrid" => 120,
                    "address" => Construqt::Addresses.add_ip("2000:dead:bead:8912::1/128").add_ip("192.168.89.10/32"),
                    "interfaces" => [
                      Construqt::Interfaces.find(Construqt::Hosts.find("muc-r01"), "v120"),
                      Construqt::Interfaces.find(Construqt::Hosts.find("muc-r02"), "v120")
                    ])

```
