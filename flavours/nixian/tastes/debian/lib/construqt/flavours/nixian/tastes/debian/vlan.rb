module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class Vlan
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Vlan, Vlan)
        end
      end
    end
  end
end
