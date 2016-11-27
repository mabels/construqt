module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Systemd
          class DhcpV4Relay
            def render(iface, taste_type, taste)
            end
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
