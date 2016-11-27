module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class IpAddr
            def render(iface, taste_type, taste)
              writer = etc_network_interfaces.get(iface, ud.ifname)
              prefix = ud.ip.ipv6? ? "-6 " : "-4 "
              writer.lines.up("ip #{prefix}addr add #{ud.ip.to_string} dev #{ud.ifname}")
              writer.lines.down("ip #{prefix}addr del #{ud.ip.to_string} dev #{ud.ifname}")
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::IpAddr, IpAddr)
        end
      end
    end
  end
end
