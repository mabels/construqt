module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Flat
          class DhcpV4
            def render(iface, taste_type, taste)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::DhcpV4, DhcpV4)
        end
      end
    end
  end
end
