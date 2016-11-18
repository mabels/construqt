module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class Loopback
            def render(iface, taste_type, taste)
              writer = etc_network_interfaces.get(iface, iface.name)
              writer.header.mode(Result::EtcNetworkInterfaces::Entry::Header::MODE_LOOPBACK) if iface.address.loopback?
            end
          end
          add(Entities::Loopback, Loopback)
        end
      end
    end
  end
end
