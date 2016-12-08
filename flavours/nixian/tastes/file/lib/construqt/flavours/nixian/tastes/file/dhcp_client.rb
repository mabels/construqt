module Construqt
  module Flavour
    module Nixian
      module Tastes
        module File
          class DhcpClient
            def on_add(ud, taste, iface, me)
              # binding.pry if iface.name == "etcbind-2"
              fsrv = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkNetworkUd::OncePerHost)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::DhcpClient, DhcpClient)
        end
      end
    end
  end
end
