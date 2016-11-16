module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result

            class EtcSystemdService
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
end
