

module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Entities
          class IpRoute
            attr_reader :route, :ifname
            def initialize(route, ifname)
              @route = route
              @ifname = ifname
            end
          end
          add(IpRoute)
        end
      end
    end
  end
end
