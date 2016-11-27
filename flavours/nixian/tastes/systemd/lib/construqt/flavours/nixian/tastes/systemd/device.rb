module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Systemd
          class Device
            def render(iface, taste_type, taste)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Device, Device)
        end
      end
    end
  end
end
