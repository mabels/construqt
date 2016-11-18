

module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Entities
          class DhcpV4Relay
            attr_reader :inbounds, :upstreams
            def initialize(inbounds, upstreams)
              @inbounds = inbounds
              @upstreams = upstreams
            end
          end
          add(DhcpV4Relay)
        end
      end
    end
  end
end
