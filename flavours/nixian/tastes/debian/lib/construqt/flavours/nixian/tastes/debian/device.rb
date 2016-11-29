module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class Device
            def on_add(ud, taste, iface, me)
              # binding.pry
              eni = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost)
              writer = eni.get(iface, me.ifname)
              writer.header.protocol(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost::Entry::Header::PROTO_INET4)
              writer.lines.add(iface.delegate.flavour) if iface.delegate.flavour
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Device, Device)
        end
      end
    end
  end
end
