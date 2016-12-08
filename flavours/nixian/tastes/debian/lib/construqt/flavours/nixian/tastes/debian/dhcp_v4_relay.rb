module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class DhcpV4Relay
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::DhcpV4Relay, DhcpV4Relay)
        end
      end
    end
  end
end
