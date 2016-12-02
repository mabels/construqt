
module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          class ServiceFactory

            def initialize
              @services = {}
            end

            def add_renderer(name, renderer)
              @services[name] = renderer
            end

            def get_renderer(service)
              found = @services[service.name]
              throw "service type unknown #{service.name} #{service.class.name}" unless found
              render.factory(service)
            end
          end
        end
      end
    end
  end
end
