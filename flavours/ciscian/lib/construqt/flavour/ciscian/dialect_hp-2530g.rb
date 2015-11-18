require_relative "dialect_hp-2510g.rb"
module Construqt
  module Flavour
    class Ciscian
      class Hp2530g < Hp2510g
        def self.name
          'hp-2530g'
        end

        def write_sntp(host)
          if host.region.network.ntp.servers.first_ipv4 
            @result.add("sntp server priority 1").add(host.region.network.ntp.servers.first_ipv4)
            @result.add("timesync sntp")
            @result.add("sntp unicast")
          end
        end
      end
      Construqt::Flavour::Ciscian.add_dialect(Hp2530g)
    end
  end
end
