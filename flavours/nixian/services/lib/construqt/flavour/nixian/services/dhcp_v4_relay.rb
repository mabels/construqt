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

        class DhcpV4RelayAction
        end

        class DhcpV4RelayFactory
          attr_reader :machine
          def initialize(service_factory)
            @machine = service_factory.machine
              .service_type(DhcpV4Relay)
          end

          def produce(host, srv_inst, ret)
            DhcpClientAction.new
          end
        end
      end
    end
  end
end
