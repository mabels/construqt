require_relative "dialect_hp-2510g.rb"
module Construqt
  module Flavour
    class Ciscian
      class Hp2530g < Hp2510g
        def self.name
          'hp-2530g'
        end
        def add_host(host)
          @result.add("hostname").add(@result.host.name).quotes
          @result.add("max-vlans").add(64)
          @result.add("snmp-server community \"public\"")

          if host.delegate.contact
            @result.add("snmp-server contact").add(host.delegate.contact).quotes
          end

          if host.delegate.location
            @result.add("snmp-server location").add(host.delegate.location).quotes
          end

          #enable ssh per default
          @result.add("ip ssh")
          @result.add("ip ssh filetransfer")

          #disable tftp per default
          @result.add("no tftp client")
          @result.add("no tftp server")

          #timezone defaults
          @result.add("time timezone").add(60)
          @result.add("time daylight-time-rule").add("Western-Europe")
          @result.add("console inactivity-timer").add(10)

          @result.host.interfaces.values.each do |iface|
            next unless iface.delegate.address
            iface.delegate.address.routes.each do |route|
              @result.add("ip route #{route.dst.to_s} #{route.dst.netmask} #{route.via.to_s}")
            end
          end

          if host.delegate.sntp
            @result.add("sntp server priority 1").add(host.delegate.sntp)
            @result.add("timesync sntp")
            @result.add("sntp unicast")
          end

          if host.delegate.plug_in
              @result.add(host.delegate.plug_in)
          end

          if host.delegate.logging
            @result.add("logging").add(host.delegate.logging)
          end
        end
      end
      Construqt::Flavour::Ciscian.add_dialect(Hp2530g)
    end
  end
end
