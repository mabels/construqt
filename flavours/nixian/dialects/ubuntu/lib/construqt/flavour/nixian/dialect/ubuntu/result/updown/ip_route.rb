

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result
            module UpDown
              class IpRoute
                attr_reader :route, :ifname
                def initialize(route, ifname)
                  @route = route
                  @ifname = ifname
                end
              end
            end
          end
        end
      end
    end
  end
end
