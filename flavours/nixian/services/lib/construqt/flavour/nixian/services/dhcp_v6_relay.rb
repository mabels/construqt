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
        class DhcpV6RelayAction
        end

        class DhcpV6RelayFactory
          attr_reader :machine
          def initialize(service_factory)
            @machine = service_factory.machine
              .service_type(DhcpV6Relay)
          end

          def produce(host, srv_inst, ret)
            DhcpV6RelayAction.new
          end
        end
      end
    end
  end
end
