module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Systemd
          class IpRoute
            def render(iface, taste_type, taste)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::IpRoute, IpRoute)
        end
      end
    end
  end
end
