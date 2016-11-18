module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class DhcpV6
            def render(iface, taste_type, taste)
              writer = etc_network_interfaces.get(iface)
              writer.header.dhcpv6
            end
          end
          add(Entities::DhcpV6, DhcpV6)
        end
      end
    end
  end
end
