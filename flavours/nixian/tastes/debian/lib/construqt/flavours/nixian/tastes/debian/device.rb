module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class Device
            def render(iface, taste_type, taste)
              writer = etc_network_interfaces.get(iface, ud.ifname)
              writer.header.protocol(Result::EtcNetworkInterfaces::Entry::Header::PROTO_INET4)
              writer.lines.add(iface.delegate.flavour) if iface.delegate.flavour
            end
          end
          add(Entities::Device, Device)
        end
      end
    end
  end
end
