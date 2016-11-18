module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class LinkMtuUpDown
            def render(iface, taste_type, taste)
              writer = etc_network_interfaces.get(iface, ud.ifname)
              writer.lines.up("ip link set mtu #{ud.mtu} dev #{ud.ifname} up")
              writer.lines.down("ip link set dev #{ud.ifname} down")
            end
          end
          add(Entities::LinkMtuUpDown, LinkMtuUpDown)
        end
      end
    end
  end
end
