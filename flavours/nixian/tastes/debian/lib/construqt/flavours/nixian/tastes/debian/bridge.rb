module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class Bridge
            def render(iface, taste_type, taste)
              etc_network_interfaces.get(iface).lines.add("bridge_ports none", 0)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Bridge, Bridge)
        end
      end
    end
  end
end
