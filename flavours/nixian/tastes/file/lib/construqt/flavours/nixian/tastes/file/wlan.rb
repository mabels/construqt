module Construqt
  module Flavour
    module Nixian
      module Tastes
        module File
          class Wlan
            def on_add(ud, taste, iface, me)
              fsrv = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkNetworkUd::OncePerHost)
              fsrv.up("# up wlan is not impl")
              fsrv.down("# down wlan is not impl")
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Wlan, Wlan)
        end
      end
    end
  end
end
