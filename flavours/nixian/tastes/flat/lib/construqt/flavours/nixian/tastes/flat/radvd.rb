module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Flat
          class Radvd
            def render(iface, taste_type, taste)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Radvd, Radvd)
        end
      end
    end
  end
end
