module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Systemd
          class Bridge
            def render(iface, taste_type, taste)
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
