module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class OpenVpn
            def render(iface, taste_type, taste)
              writer = etc_network_interfaces.get(iface)
              writer.lines.up("mkdir -p /dev/net", :extra)
              writer.lines.up("mknod /dev/net/tun c 10 200", :extra)
              writer.lines.up("/usr/sbin/openvpn --config /etc/openvpn/#{iface.name}.conf", :extra)
              writer.lines.down("kill $(cat /run/openvpn.#{iface.name}.pid)", :extra)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::OpenVpn, OpenVpn)
        end
      end
    end
  end
end
