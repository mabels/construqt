module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class Wlan
            def on_add(ud, taste, iface, me)
              wlan = iface
              eni = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkInterfaces::OncePerHost)
              writer = eni.get(iface)
              writer.lines.add(Construqt::Util.render(binding, "wlan_interfaces.erb"), 0)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Wlan, Wlan)
        end
      end
    end
  end
end
