

module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Entities
          class Bgp
            attr_reader :ip, :ifname
            def initialize(ip, ifname)
              @ip = ip
              @ifname = ifname
            end
          end
          add(Bgp)
        end
      end
    end
  end
end
