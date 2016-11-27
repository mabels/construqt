module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Flat
          class Tunnel
            def render(iface, taste_type, taste)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Tunnel, Tunnel)
        end
      end
    end
  end
end
