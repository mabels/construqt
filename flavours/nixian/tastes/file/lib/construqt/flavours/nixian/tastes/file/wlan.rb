module Construqt
  module Flavour
    module Nixian
      module Tastes
        module File
          class Wlan
            def render(iface, taste_type, taste)
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Wlan, Wlan)
        end
      end
    end
  end
end
