module Construqt
  module Flavour
    module Nixian
      module Tastes
        module File
          class Loopback
            def render(iface, taste_type, taste)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Loopback, Loopback)
        end
      end
    end
  end
end
