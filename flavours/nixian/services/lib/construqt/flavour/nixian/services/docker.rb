
module Construqt
  module Flavour
    module Nixian
      module Services
        module Docker
          class Service
            include Construqt::Util::Chainable
            chainable_attr :image, "ubuntu:16.04"
            chainable_attr :app_start_script, ""
            chainable_attr :pkt_man, :apt
            chainable_attr :version, ""
            chainable_attr_value :docker_pkg

            chainable_attr_value :tlscacert
            chainable_attr_value :tlscert
            chainable_attr_value :tlskey
            chainable_attr_value :tlsverify
            chainable_attr_value :ip_masq
            chainable_attr_value :storage_driver
            chainable_attr_value :fixed_cidr_v6
            chainable_attr_value :ipv6

            def initialize
              @packages = []
              @hosts = []
              docker_pkg("docker.io")
              # binding.pry
            end

            def daemon_json
              ret = {}
              if @hosts.empty?
                ret['hosts'] = ["fd://"]
              else
                ret['hosts'] = @hosts
              end
              ret["tlscacert"] = get_tlscacert if get_tlscacert
              ret["tlscert"] = get_tlscert if get_tlscert
              ret["tlskey"] = get_tlskey if get_tlskey
              ret["tlsverify"] = get_tlsverify if defined?(get_tlsverify)
              ret["ip-masq"] = get_ip_masq if defined?(get_ip_masq)
              ret["storage-driver"] = get_storage_driver if get_storage_driver
              ret["fixed-cidr-v6"] = get_fixed_cidr_v6 if get_fixed_cidr_v6
              ret["ipv6"] = get_ipv6 if defined?(get_ipv6)
              ret
            end

            def hosts(a)
              @hosts << a
              self
            end

            def get_hosts()
              @hosts
            end

            def package(pkg)
              @packages.push(pkg)
              self
            end

            def get_packages
              @packages
            end

            def map(h, d)
              @maps ||= {}
              @maps[h] = d
              self
            end

            def get_maps
              @maps || {}
            end

            def privileged
              @privileged = true
              self
            end

            def get_privileged
              @privileged || false
            end

            def is_apt
              get_pkt_man == :apt
            end

            def is_apk
              get_pkt_man == :apk
            end
          end

          class Action
            attr_reader :host, :docker
            def initialize(host, docker)
              @host = host
              @docker = docker
            end

            def activate(ctx)
              @context = ctx
            end

            def i_ma_the_mother?(host)
              host.region.hosts.get_hosts.find { |h| host.eq(h.mother) }
            end


            def render(result, host, docker)

              # binding.pry
              # result.add(Docker, Construqt::Util.render(binding, "docker_starter.sh.erb"),
              #            Construqt::Resources::Rights.root_0755,
              #            "root", "docker-starter.sh")

              # binding.pry if host.name == "etcbind-1"
              result.add(Docker, Construqt::Util.render(binding, "docker_dockerfile.erb"),
                         Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::DOCKER),
                         "var", "lib", "docker", "construqt", host.name, "Dockerfile")
              result.add(Docker, Construqt::Util.render(binding, "docker_run.sh.erb"),
                         Construqt::Resources::Rights.root_0755(Construqt::Resources::Component::DOCKER),
                         "var", "lib", "docker", "construqt", host.name, "docker_run.sh")

              up_downer = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::UpDowner::OncePerHost)
              up_downer.add(@host, Taste::Container.new(host))

              #
              # Container.write_deployers(@host, lambda{ |h| h.docker_deploy }, Docker,
              #   lambda{ |h| [] }).each do |docker|
              #   end
              # end
              #
              # deployer.sh
              # start interfaces
              # write .dockerignore
              # write Dockerfile
              # write #{host.name}-docker-start.sh
            end

            def build_config_host #(host, service)
              packager = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Packager::OncePerHost)
              # binding.pry if @host.name == "bdog"
              packager.register(Construqt::Resources::Component::DOCKER).add(docker.get_docker_pkg)

              result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
              host.region.hosts.get_hosts.select {|h| host.eq(h.mother) }.each do |d_host|
                # binding.pry
                d_host.services.by_type_of(Service).each do |d_srv|
                  render(result, d_host, d_srv)
                end
              end

              docker_ifaces = {}
              host.interfaces.values.each do |iface|
                binding.pry unless iface.cable
                iface.cable.connections.each do |ciface|
                  if host.eq(ciface.iface.host.mother)
                    docker_ifaces[iface.name] = iface
                  end
                end
              end

              docker_ifaces.values.each do |iface|
                next unless iface.address
                docker_up = Construqt::Util.render(binding, "docker_up.erb")
                result.add(self.class, docker_up, Construqt::Resources::Rights.root_0755,
                           'etc', 'network', "#{iface.name}-docker-up.sh")
                docker_down = Construqt::Util.render(binding, "docker_down.erb")
                result.add(self.class, docker_down, Construqt::Resources::Rights.root_0755,
                           'etc', 'network', "#{iface.name}-docker-down.sh")
                up_downer = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::UpDowner::OncePerHost)
                up_downer.add(@host, Taste::Interface.new(iface))
              end

              unless self.i_ma_the_mother?(@host)
                # binding.pry
                result.add(Docker, Construqt::Util.render(binding, "docker_starter.sh.erb"),
                           Construqt::Resources::Rights.root_0755,
                           "root", "docker-starter.sh")
              end
            end
            def commit
              return unless self.i_ma_the_mother?(@host)
              result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
              result.add(self, JSON.pretty_generate(docker.daemon_json),
                Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::DOCKER),
                "/etc", "docker", "daemon.json")
              # def self.write_deployers(host, forme, clazz, rights, path_action)
              host.region.hosts.get_hosts.select {|h| @host.eq(h.mother) }.each do |lxc|
                result.add(self, Util.read_str(host.region, lxc.name, "deployer.sh"),
                  Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::DOCKER),
                  "/var", "lib", "docker", "construqt", lxc.name, "deployer.sh").skip_git
              end
            end
          end


          module Taste
            class Interface
              attr_reader :iface
              def initialize(iface)
                @iface = iface
              end

              class Systemd
                def on_add(ud, taste, _, me)
                  ess = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcSystemdService::OncePerHost)
                  ess.get("construqt-#{me.iface.name}-docker-network.service") do |srv|
                    # binding.pry
                    srv.description("added own network #{me.iface.name} to docker")
                       .type("oneshot")
                       .remain_after_exit
                       .after("docker.socket")
                       .after("sys-devices-virtual-net-#{me.iface.name}.device")
                       .requires("docker.socket")
                       .requires("sys-devices-virtual-net-#{me.iface.name}.device")
                       .exec_start("/bin/sh /etc/network/#{me.iface.name}-docker-up.sh")
                       .exec_stop("/bin/sh /etc/network/#{me.iface.name}-docker-down.sh")
                       .wanted_by("multi-user.target")
                  end

                end
                def activate(ctx)
                  @context = ctx
                  self
                end
              end
            end

            class Container
              attr_reader :container
              def initialize(container)
                @container = container
              end

              class Systemd
                def on_add(ud, taste, _, me)
                  ess = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcSystemdService::OncePerHost)
                  ess.get("construqt-#{me.container.name}-docker.service") do |srv|
                    # binding.pry
                    srv.description("starts docker container #{me.container.name}")
                       .type("simple")
                       .after("docker.socket")
                       .requires("docker.socket")
                       .exec_start("/bin/sh /var/lib/docker/construqt/#{me.container.name}/docker_run.sh")
                       .exec_stop("/usr/bin/docker kill run_#{me.container.name}")
                       .wanted_by("multi-user.target")
                    me.container.interfaces.values.select do |i|
                      i.name != "lo" && i.cable.connections.length > 0
                    end.each do |iface|
                      throw "multipe cable" if iface.cable.connections.length > 1
                      name = iface.cable.connections.first.iface.name
                      srv.after("construqt-#{name}-docker-network.service")
                      srv.requires("sys-subsystem-net-devices-#{name}.device")
                    end
                  end
                end
                def activate(ctx)
                  @context = ctx
                  self
                end
              end
            end


          end


          class Factory
            attr_reader :machine
            def start(service_factory)
              # binding.pry
              @machine ||= service_factory.machine
                .service_type(Service)
                .depend(Result::Service)
                .activator(Construqt::Flavour::Nixian::Services::UpDowner::Activator.new
                  .entity(Taste::Interface)
                  .add(Construqt::Flavour::Nixian::Tastes::Systemd::Factory, Taste::Interface::Systemd))
                .activator(Construqt::Flavour::Nixian::Services::UpDowner::Activator.new
                  .entity(Taste::Container)
                  .add(Construqt::Flavour::Nixian::Tastes::Systemd::Factory, Taste::Container::Systemd))
            end

            def produce(host, srv_inst, ret)
              Action.new(host, srv_inst)
            end
          end
        end
      end
    end
  end
end

#
#
# module Construqt
#   module Flavour
#     module Nixian
#       module Dialect
#         module Ubuntu
#           module Docker
#
#             def self.belongs_to_mother?
#               false
#             end

#
#             def self.write_deployers(host)
#               Container.write_deployers(host,
#                 lambda{ |h| h.docker_deploy }, Docker,
#                     Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::DOCKER),
#                 lambda{ |h| ["/var", "lib", "docker", "construqt", h.name, "deployer.sh"] }).each do |docker|
#               end

#             end

#
#             def self.deploy_mother(host)
#               []
#             end

#
#             def self.deploy_docker(host)
#               []
#             end

#
#             def self.deploy(host)
#               # if this a mother
#               return deploy_mother(host) unless Container.i_ma_the_mother?(host)
#               return deploy_docker(host)
#             end

#
#
#           end

#         end

#       end

#     end

#   end

# end

# def render_systemd
#   #ExecStart=/usr/bin/docker run --env foo=bar --name redis_server redis
#   #ExecStop=/usr/bin/docker stop -t 2 redis_server
#   #ExecStopPost=/usr/bin/docker rm -f redis_server
#   systemd = Result::SystemdService.new("construqt-docker@#{docker.name}.service")
#     .description("docker-#{docker.name}")
#     .type("simple")
#     .after("docker.service")
#     .after("network-online.target")
#     .requires("docker.service")
#     .requires("network-online.target")
#     .exec_start("/bin/sh /var/lib/docker/construqt/#{docker.name}/docker_run.sh")
#     .exec_stop("/usr/bin/docker stop -t 2 run_#{docker.name}")
#     .exec_stop_post("/usr/bin/docker rm -f run_#{docker.name}")
#     .wanted_by("multi-user.target")
#   host.result.add(systemd, systemd.as_systemd_file,
#                   Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::SYSTEMD),
#                   "etc", "systemd", "system", systemd.get_name)
# end
