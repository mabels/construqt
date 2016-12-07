module Construqt
  module Flavour
    module Nixian
      module Tastes
        module File
          class Tunnel
            def on_add(ud, taste, iface, me)
              # binding.pry if iface.name == "etcbind-2"
              fsrv = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkNetworkUd::OncePerHost)
              fsrv.up("ip -#{me.cfg.prefix} tunnel add #{iface.name} mode #{me.cfg.mode} local #{me.local} remote #{me.remote}")
              fsrv.down("ip -#{me.cfg.prefix} tunnel del #{iface.name}")
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Tunnel, Tunnel)
        end
      end
    end
  end
end
