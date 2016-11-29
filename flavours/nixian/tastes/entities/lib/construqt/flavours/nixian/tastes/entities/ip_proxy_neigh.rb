

module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Entities
          class IpProxyNeigh
            attr_reader :iface #, :ifname
            def initialize(iface)
              @iface = iface
            end
          end
          add(IpProxyNeigh)
        end
      end
    end
  end
end
