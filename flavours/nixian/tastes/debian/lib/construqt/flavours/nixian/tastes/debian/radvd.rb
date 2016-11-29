module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Debian
          class Radvd
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::Radvd, Radvd)
        end
      end
    end
  end
end
