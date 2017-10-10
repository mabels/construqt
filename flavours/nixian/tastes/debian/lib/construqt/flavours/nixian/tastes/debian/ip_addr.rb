module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class IpAddr
            def on_add(ud, taste, iface, me)
              eni = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost)
              writer = eni.get(iface, me.ifname)
              prefix = me.ip.ipv6? ? "-6 " : "-4 "
              writer.lines.up("ip #{prefix}addr add #{me.ip.to_string} dev #{Util.short_ifname(iface)}")
              writer.lines.down("ip #{prefix}addr del #{me.ip.to_string} dev #{Util.short_ifname(iface)}")
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
