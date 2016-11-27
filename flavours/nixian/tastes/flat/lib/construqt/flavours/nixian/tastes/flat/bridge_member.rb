module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Flat
          class BridgeMember
            def render(iface, taste_type, taste)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::BridgeMember, BridgeMember)
        end
      end
    end
  end
end
