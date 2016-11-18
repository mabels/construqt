module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class IpTables
            def render(iface, taste_type, taste)
              writer = etc_network_interfaces.get(iface)
              writer.lines.up("/sbin/iptables-restore /etc/network/iptables.cfg")
              writer.lines.up("/sbin/ip6tables-restore /etc/network/ip6tables.cfg")
            end
          end
          add(Entities::IpTables, IpTables)
        end
      end
    end
  end
end
