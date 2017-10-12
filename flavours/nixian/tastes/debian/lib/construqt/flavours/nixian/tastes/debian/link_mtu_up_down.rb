module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class LinkMtuUpDown
            def on_add(ud, taste, iface, me)
              eni = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost)
              writer = eni.get(iface, me.ifname)
              #binding.pry if Util.short_ifname(iface) != iface.name
              writer.lines.up("ip link set mtu #{me.mtu} dev #{Util.short_ifname(iface)} up")
              writer.lines.down("ip link set dev #{Util.short_ifname(iface)} down")
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::LinkMtuUpDown, LinkMtuUpDown)
        end
      end
    end
  end
end
