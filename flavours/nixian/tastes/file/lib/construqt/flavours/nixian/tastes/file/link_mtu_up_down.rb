module Construqt
  module Flavour
    module Nixian
      module Tastes
        module File
          class LinkMtuUpDown
            def on_add(ud, taste, iface, me)
              # binding.pry if iface.name == "etcbind-2"
              fsrv = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkNetworkUd::OncePerHost)
              fsrv.up("ip link set mtu #{me.mtu} dev #{Util.short_ifname(iface)} up")
              fsrv.down("ip link set dev #{Util.short_ifname(iface)} down")
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
