module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class Loopback
            def on_add(ud, taste, iface, me)
              eni = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost)
              writer = eni.get(iface)
              writer.header.mode(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost::Entry::Header::MODE_LOOPBACK) if iface.address.loopback?
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
