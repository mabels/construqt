

module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Entities
          class DhcpClient
            attr_reader :ifname
            def initialize(ifname)
              @ifname = ifname
            end
          end
          add(DhcpClient)
        end
      end
    end
  end
end
