module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Flat
          class DhcpV6Relay
            def render(iface, taste_type, taste)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::DhcpV6Relay, DhcpV6Relay)
        end
      end
    end
  end
end
