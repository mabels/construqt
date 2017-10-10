module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class Tunnel
            def on_add(ud, taste, iface, me)
              # binding.pry
              eni = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost)
              writer = eni.get(iface)
              writer.lines.up("ip -#{me.cfg.prefix} tunnel add #{Util.short_ifname(iface)} mode #{me.cfg.mode} local #{me.local} remote #{me.remote}")
              writer.lines.down("ip -#{me.cfg.prefix} tunnel del #{Util.short_ifname(iface)}")
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
