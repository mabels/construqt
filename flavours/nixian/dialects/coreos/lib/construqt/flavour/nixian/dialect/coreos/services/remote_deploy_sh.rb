


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

                def i_ma_the_mother?(host)
                  host.region.hosts.get_hosts.find { |h| host.eq(h.mother) }
                end

                def build_config_host
                  Util.write_str(@host.region, Construqt::Util.render(binding, "remote-deploy.sh.erb"),
                    @host.name, 'remote-deploy.sh')
                  self.i_ma_the_mother?(@host) && @host.region.hosts.get_hosts.select do |h|
                    @host.eq(h.mother)
                  end.each do |docker|
                    Util.write_str(@host.region, Construqt::Util.render(binding, "restart-docker.sh.erb"),
                        @host.name, "restart-#{docker.name}.sh")
                  end
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
