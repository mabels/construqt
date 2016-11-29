module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class DhcpV6
            def on_add(ud, taste, iface, me)
              eni = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost)
              writer = eni.get(iface, me.ifname)
              writer.header.dhcpv6
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::DhcpV6, DhcpV6)
        end
      end
    end
  end
end
