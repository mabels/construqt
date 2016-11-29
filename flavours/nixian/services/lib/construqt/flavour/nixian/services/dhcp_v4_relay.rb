module Construqt
  module Flavour
    module Nixian
      module Services
        module DhcpV4Relay
          class Service
            attr_reader :name, :inbound_tag, :upstream_tag
            attr_accessor :services
            def initialize(name, inbound_tag, upstream_tag)
              @name = name
              @inbound_tag = inbound_tag
              @upstream_tag = upstream_tag
            end
          end

          class Action
          end

          class Factory
            attr_reader :machine
            def initialize(service_factory)
              @machine = service_factory.machine
                .service_type(Service)
                .depend(Result::Service)
            end

            def produce(host, srv_inst, ret)
              Action.new
            end
          end
        end
      end
    end
  end
end
