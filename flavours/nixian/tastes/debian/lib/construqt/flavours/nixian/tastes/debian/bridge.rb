module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class Bridge
            def on_add(ud, taste, iface, me)
              eni = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost)
              writer = eni.get(iface, me.ifname)
              writer.lines.add("bridge_ports none", 0)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Bridge, Bridge)
        end
      end
    end
  end
end
