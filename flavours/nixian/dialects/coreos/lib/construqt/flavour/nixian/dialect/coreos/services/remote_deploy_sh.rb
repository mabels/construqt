


module Construqt
  module Flavour
    module Nixian
      module Dialect
        module CoreOs
          module Services
            module RemoteDeploySh
              class Service
              end
              class Action
              end

              class OncePerHost

                def activate(context)
                  @context = context
                end

                def attach_host(host)
                  @host = host
                end

                def build_config_host
                  Util.write_str(@host.region, Construqt::Util.render(binding, "remote-deploy.sh.erb"),
                    @host.name, 'remote-deploy.sh')
                end

                def commit
                  # binding.pry
                end
              end

              class Factory
                attr_reader :machine
                def start(service_factory)
                  @machine ||= service_factory.machine
                    .service_type(Service)
                    .result_type(OncePerHost)
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
