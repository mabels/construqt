module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Flat
          class IpSecConnect
            def render(iface, taste_type, taste)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::IpSecConnect, IpSecConnect)
        end
      end
    end
  end
end
