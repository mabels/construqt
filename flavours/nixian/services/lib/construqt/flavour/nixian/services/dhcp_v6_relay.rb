module Construqt
  module Flavour
    module Nixian
      module Services
        class DhcpV6Relay
          attr_reader :name, :inbound_tag, :upstream_tag
          attr_accessor :services
          def initialize(name, inbound_tag, upstream_tag)
            @name = name
            @inbound_tag = inbound_tag
            @upstream_tag = upstream_tag
          end
        end

        class DhcpV6RelayImpl
          attr_reader :service_type
          def initialize
            @service_type = DhcpV6Relay
          end

          def attach_service(service)
            @service = service
          end
        end
      end
    end
  end
end
