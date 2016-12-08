module Construqt
  module Flavour
    module Nixian
      module Tastes
        module File
          class Bgp
            def on_add(ud, taste, iface, me)
              # binding.pry if iface.name == "etcbind-2"
              fsrv = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkNetworkUd::OncePerHost)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Bgp, Bgp)
        end
      end
    end
  end
end
