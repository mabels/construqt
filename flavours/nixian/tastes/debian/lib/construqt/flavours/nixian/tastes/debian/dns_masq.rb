module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class DnsMasq
            def activate(ctx)
              @context = ctx
              self
            end

            def on_add(ud, taste, iface, me)
              return unless iface.dhcp
              host.result.add_component(Construqt::Resources::Component::DNSMASQ)
              eni = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost)
              writer = eni.get(iface, ud.ifname)
              writer.lines.up(up(ud.ifname), :extra)
              writer.lines.down(down(ud.ifname), :extra)
            end
          end
          add(Entities::DnsMasq, DnsMasq)
        end
      end
    end
  end
end
