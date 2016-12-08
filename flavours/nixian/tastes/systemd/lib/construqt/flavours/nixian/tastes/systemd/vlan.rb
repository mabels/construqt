module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Systemd
          class Vlan
            def render(iface, taste_type, taste)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Vlan, Vlan)
        end
      end
    end
  end
end
