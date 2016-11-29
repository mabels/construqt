module Construqt
  module Flavour
    module Nixian
      module Services
        module EtcSystemdService

          class OncePerHost
            attr_reader :services
            def initialize
              @services = {}
            end

            def get(name, &block)
              service = @services[name]
              unless service
                @services[name] = service = SystemdService.new(name)
                block && block.call(service)
              end

              service
            end

            def commit(result)
              services.values.each do |service|
                service.commit(result)
              end
            end
          end
        end
      end
    end
  end
end
