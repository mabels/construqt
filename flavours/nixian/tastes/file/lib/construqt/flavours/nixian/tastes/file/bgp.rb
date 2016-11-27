module Construqt
  module Flavour
    module Nixian
      module Tastes
        module File
          class Bgp
            def render(iface, taste_type, taste)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Bgp, Bgp)
        end
      end
    end
  end
end
