module Construqt
  module Flavour
    module Nixian
      module Tastes
        module File
          class Loopback
            def on_add(ud, taste, iface, me)
              fsrv = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkNetworkUd::OncePerHost)
              fsrv.up("ip -4 addr add 127.0.0.1 dev #{iface.name}")
              fsrv.up("ip -6 addr add ::1/128 dev #{iface.name}")
              fsrv.down("ip -4 addr del 127.0.0.1/8 dev #{iface.name}")
              fsrv.down("ip -6 addr del ::1/128 dev #{iface.name}")
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Loopback, Loopback)
        end
      end
    end
  end
end
