
module Construqt
  module Flavour
    module Nixian
      module Services
        class Ssh
        end

        class SshAction
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
            akeys = host.region.users.get_authorized_keys(host)

            result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::ResultOncePerHost)
            #host.result.add(self, skeys.join(), Construqt::Resources::Rights.root_0644, "etc", "shadow.merge")
            result.add(self, akeys.join("\n"),
              Construqt::Resources::Rights.root_0600,
              "root", ".ssh", "authorized_keys")

            result.add(self, Construqt::Util.render(binding, "host_ssh.erb"),
              Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::SSH),
              "etc", "ssh", "sshd_config")
          end

          def commit
          end

        end

        class SshFactory
          attr_reader :machine
          def initialize(service_factory)
            @machine = service_factory.machine
              .service_type(Ssh)
              .depend(Result)
          end

          def produce(host, srv_inst, ret)
            SshAction.new(host)
          end
        end

      end
    end
  end
end
