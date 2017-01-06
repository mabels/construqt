
module Construqt
  module Flavour
    module Nixian
      module Dialect
        module CoreOs
          module Services
            module SshAuthorizedKeysD
              class Service
              end

              class Action
                attr_reader :host

                def initialize(host)
                  @host = host
                end

                def activate(ctx)
                  @context = ctx
                end

                def build_interface(iface)
                end

                def build_config_host # (host, service)
                  users = host.region.users.get_authorized_users(host)
                  result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
                  # host.result.add(self, skeys.join(), Construqt::Resources::Rights.root_0644, "etc", "shadow.merge")
                  users.each do |user|
                    # binding.pry
                    result.add(self, user.public_key.lines.map{ |i| i.strip }.join("\n")+"\n",
                               Construqt::Resources::Rights.root_0600,
                               'root', '.ssh', 'authorized_keys.d', user.name)
                  end

                end

                def commit
                end
              end

              class Factory
                attr_reader :machine
                def start(service_factory)
                  @machine ||= service_factory.machine
                    .service_type(Service)
                    .depend(Construqt::Flavour::Nixian::Services::Result::Service)
                end

                def produce(host, _srv_inst, _ret)
                  Action.new(host)
                end
              end
            end
          end
        end
      end
    end
  end
end
