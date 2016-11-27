module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Flat
          class DnsMasq
            def render(iface, taste_type, taste)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::DnsMasq, DnsMasq)
        end
      end
    end
  end
end
