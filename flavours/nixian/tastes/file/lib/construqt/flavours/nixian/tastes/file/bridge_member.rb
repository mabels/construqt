
module Construqt
  module Flavour
    module Nixian
      module Tastes
        module File
          class BridgeMember
            def on_add(ud, taste, iface, me)
              binding.pry if iface.host.name == "thieso"
              fsrv = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkNetworkUd::OncePerHost)
              fsrv.up "brctl addif #{me.bname} #{me.ifname}"
              fsrv.down "brctl delif #{me.bname} #{me.ifname}"
            end

            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::BridgeMember, BridgeMember)
        end
      end
    end
  end
end
