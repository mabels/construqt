require_relative 'hp2510g.rb'
module Construqt
  module Flavour
    class Ciscian
      module Dialect
        module Hp
          class Hp2530g < Hp2510g
            def write_sntp(host)
              if host.region.network.ntp.servers.first_ipv4
                host.result.add('sntp server priority 1').add(host.region.network.ntp.servers.first_ipv4)
                host.result.add('timesync sntp')
                host.result.add('sntp unicast')
              end
            end
          end
          #Construqt::Flavour::Ciscian.add_dialect(Hp2530g)
        end
      end
    end
  end
end
