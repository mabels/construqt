module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          module Services
            class Docker

              def render_systemd
                #ExecStart=/usr/bin/docker run --env foo=bar --name redis_server redis
                #ExecStop=/usr/bin/docker stop -t 2 redis_server
                #ExecStopPost=/usr/bin/docker rm -f redis_server
                systemd = Result::SystemdService.new("construqt-docker@#{docker.name}.service")
                          .description("docker-#{docker.name}")
                          .type("simple")
                          .after("docker.service")
                          .after("network-online.target")
                          .requires("docker.service")
                          .requires("network-online.target")
                          .exec_start("/bin/sh /var/lib/docker/construqt/#{docker.name}/docker_run.sh")
                          .exec_stop("/usr/bin/docker stop -t 2 run_#{docker.name}")
                          .exec_stop_post("/usr/bin/docker rm -f run_#{docker.name}")
                          .wanted_by("multi-user.target")
                host.result.add(systemd, systemd.as_systemd_file,
                  Construqt::Resources::Rights.root_0644(Construqt::Flavour::Nixian::Dialect::Ubuntu::Systemd),
                  "etc", "systemd", "system", systemd.get_name)
              end


              def render(host, docker)
                # binding.pry
                docker.result.add(Docker, Construqt::Util.render(binding, "docker_starter.sh.erb"),
                  Construqt::Resources::Rights.root_0755,
                  "root", "docker-starter.sh")

                # binding.pry if host.name == "etcbind-1"
                host.result.add(Docker, Construqt::Util.render(binding, "docker_dockerfile.erb"),
                  Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::UNREF),
                  "var", "lib", "docker", "construqt", docker.name, "Dockerfile")
                host.result.add(Docker, Construqt::Util.render(binding, "docker_run.sh.erb"),
                  Construqt::Resources::Rights.root_0755(Construqt::Resources::Component::UNREF),
                  "var", "lib", "docker", "construqt", docker.name, "docker_run.sh")

                # deployer.sh
                # start interfaces
                # write .dockerignore
                # write Dockerfile
                # write #{host.name}-docker-start.sh
              end


              def build_config_host(host)
                host.region.hosts.get_hosts.select {|h| host.eq(h.mother) }.each do |docker|
                  next unless docker.docker_deploy
                  render(host, docker)
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
                  host.result.add(self.class, docker_up, Construqt::Resources::Rights.root_0755,
                    'etc', 'network', "#{iface.name}-docker-up.sh")
                end
              end
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
