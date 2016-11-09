module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          module Docker

            def self.belongs_to_mother?
              false
            end

            def self.write_deployers(host)
              Container.write_deployers(host,
                lambda{ |h| h.docker_deploy }, Docker,
                    Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::DOCKER),
                lambda{ |h| ["/var", "lib", "docker", "construqt", h.name, "deployer.sh"] }).each do |docker|
              end
            end

            def self.deploy_mother(host)
              []
            end

            def self.deploy_docker(host)
              []
            end

            def self.deploy(host)
              # if this a mother
              return deploy_mother(host) unless Container.i_ma_the_mother?(host)
              return deploy_docker(host)
            end

            def self.render(host, docker)
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





              systemd = Result::SystemdService.new(host.result, "docker-#{docker.name}.service")
                        .description("docker-#{docker.name}")
                        .type("simple")
                        .after("docker.service")
                        .after("network-online.target")
                        .requires("docker.service")
                        .requires("network-online.target")
                        .exec_start("/bin/sh /var/lib/docker/construqt/#{docker.name}/docker_run.sh")
                        .wanted_by("network-online.target")
              host.result.add(systemd, systemd.as_systemd_file,
                Construqt::Resources::Rights.root_0644(Construqt::Flavour::Nixian::Dialect::Ubuntu::Systemd),
                "etc", "systemd", "system", systemd.get_name)

              # deployer.sh
              # start interfaces
              # write .dockerignore
              # write Dockerfile
              # write #{host.name}-docker-start.sh
            end

          end
        end
      end
    end
  end
end
