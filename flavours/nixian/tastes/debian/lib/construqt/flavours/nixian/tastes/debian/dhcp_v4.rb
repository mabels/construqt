module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class DhcpV4
            def render(iface, taste_type, taste)
              writer = etc_network_interfaces.get(iface)
              writer.header.dhcpv4
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::DhcpV4, DhcpV4)
        end
      end
    end
  end
end
