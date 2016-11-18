

module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Entities
          class IpAddr
            attr_reader :ip, :ifname
            def initialize(ip, ifname)
              @ip = ip
              @ifname = ifname
            end
          end
          add(IpAddr)
        end
      end
    end
  end
end
