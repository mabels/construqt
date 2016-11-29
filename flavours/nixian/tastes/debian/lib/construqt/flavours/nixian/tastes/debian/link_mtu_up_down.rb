module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class LinkMtuUpDown
            def on_add(ud, taste, iface, me)
              eni = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost)
              writer = eni.get(iface, me.ifname)
              writer.lines.up("ip link set mtu #{me.mtu} dev #{me.ifname} up")
              writer.lines.down("ip link set dev #{me.ifname} down")
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
