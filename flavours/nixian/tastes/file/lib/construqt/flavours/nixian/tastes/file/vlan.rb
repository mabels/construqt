module Construqt
  module Flavour
    module Nixian
      module Tastes
        module File
          class Vlan
            def on_add(ud, taste, iface, me)
              binding.pry if iface.name == "etcbind-2"
              fsrv = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkNetworkUd::OncePerHost)
              fsrv.up("ip link add link #{me.dev_name(iface)} name #{iface.name} type vlan id #{me.vlan_id(iface)}")
              fsrv.down("ip link rem link #{me.dev_name(iface)} name #{iface.name} type vlan id #{me.vlan_id(iface)}")
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Vlan, Vlan)
        end
      end
    end
  end
end
