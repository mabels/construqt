module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Systemd
          class IpTables
            def render(iface, taste_type, taste)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::IpTables, IpTables)
        end
      end
    end
  end
end
