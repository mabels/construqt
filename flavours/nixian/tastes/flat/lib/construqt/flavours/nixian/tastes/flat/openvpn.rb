module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Flat
          class OpenVpn
            def render(iface, taste_type, taste)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::OpenVpn, OpenVpn)
        end
      end
    end
  end
end
