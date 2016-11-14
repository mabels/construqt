

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result
            module UpDown
              class DhcpV4Relay
                attr_reader :inbounds, :upstreams
                def initialize(inbounds, upstreams)
                  @inbounds = inbounds
                  @upstreams = upstreams
                end
              end
            end
          end
        end
      end
    end
  end
end
