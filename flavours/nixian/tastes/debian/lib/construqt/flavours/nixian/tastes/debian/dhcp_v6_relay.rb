module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class DhcpV6Relay
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
