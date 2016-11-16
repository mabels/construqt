module Construqt
  module Flavour
    module Nixian
      module Services
        class DhcpV4Relay
          attr_reader :name, :inbound_tag, :upstream_tag
          attr_accessor :services
          def initialize(name, inbound_tag, upstream_tag)
            @name = name
            @inbound_tag = inbound_tag
            @upstream_tag = upstream_tag
          end
        end

        class DhcpV4RelayImpl
          attr_reader :service_type
          def initialize
            @service_type = DhcpV4Relay
          end

          def attach_service(service)
            @service = service
          end
        end
      end
    end
  end
end
