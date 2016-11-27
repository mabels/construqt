module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Flat
          class IpProxyNeigh
            def render(iface, taste_type, taste)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::IpProxyNeigh, IpProxyNeigh)
        end
      end
    end
  end
end
