
module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class BridgeMember
            def on_add(ud, taste, iface, me)
              eni = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost)
              writer = eni.get(iface, ud.ifname)
              writer.lines.up "brctl addif #{ud.bname} #{ud.ifname}"
              writer.lines.down "brctl delif #{ud.bname} #{ud.ifname}"
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
