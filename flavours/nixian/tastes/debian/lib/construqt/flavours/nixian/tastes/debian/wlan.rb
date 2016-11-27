module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class Wlan
            def render(iface, taste_type, taste)
              wlan = iface
              etc_network_interfaces.get(iface)
                .lines.add(Construqt::Util.render(binding, "wlan_interfaces.erb"), 0)
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
