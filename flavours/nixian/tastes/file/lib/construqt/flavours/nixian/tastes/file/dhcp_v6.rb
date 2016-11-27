module Construqt
  module Flavour
    module Nixian
      module Tastes
        module File
          class DhcpV6
            def render(iface, taste_type, taste)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::DhcpV6, DhcpV6)
        end
      end
    end
  end
end
