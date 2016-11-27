module Construqt
  module Flavour
    module Nixian
      module Tastes
        module File
          class IpAddr
            def render(iface, taste_type, taste)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::IpAddr, IpAddr)
        end
      end
    end
  end
end
