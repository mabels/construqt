module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Systemd
          class Tunnel
            def on_add(ud, taste, _, me)
              # binding.pry
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Tunnel, Tunnel)
        end
      end
    end
  end
end
