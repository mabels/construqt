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
              return unless me.iface.dhcp
              pbuilder = @context.find_instances_from_type Construqt::Flavour::Nixian::Services::Packager::OncePerHost
              pbuilder.add_component(Construqt::Resources::Component::DNSMASQ)

              eni = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost)
              writer = eni.get(me.iface, me.iface.name)
              writer.lines.up me.start_cmd(false).join(" ")
            end
          end
          add(Entities::DnsMasq, DnsMasq)
        end
      end
    end
  end
end
