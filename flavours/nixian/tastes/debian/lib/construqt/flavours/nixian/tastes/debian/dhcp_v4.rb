module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class DhcpV4
            def on_add(ud, taste, iface, me)
              eni = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost)
              writer = eni.get(iface)

              writer.header.dhcpv4
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::DhcpV4, DhcpV4)
        end
      end
    end
  end
end
