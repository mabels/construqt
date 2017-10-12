module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Systemd
          class Gre
            def on_add(ud, taste, _, me)
              # binding.pry
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Gre, Gre)
        end
      end
    end
  end
end
