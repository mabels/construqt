


module Construqt
  module Flavour
    module Nixian
      module Dialect
        module CoreOs
          module Services
            module ModulesConf
              class Service
              end
              class Action
              end

              class OncePerHost

                def activate(context)
                  @context = context
                end

                def build_config_host
                  result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
                  result.add(self, Construqt::Util.render(binding, "modules.conf.erb"),
                    Construqt::Resources::Rights::root_0644,
                    "etc", "modules-load.d", "construqt.conf")
                end

                def commit
                  # binding.pry
                end
              end

              class Factory
                attr_reader :machine
                def initialize(service_factory)
                  @machine = service_factory.machine
                    .service_type(Service)
                    .result_type(OncePerHost)
                    .depend(Construqt::Flavour::Nixian::Services::Result::Service)
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
  end
end
