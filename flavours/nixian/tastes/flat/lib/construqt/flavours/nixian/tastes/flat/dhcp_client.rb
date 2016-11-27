module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Flat
          class DhcpClient
            def render(iface, taste_type, taste)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::DhcpClient, DhcpClient)
        end
      end
    end
  end
end
