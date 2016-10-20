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
                  host.result.add(Docker, Construqt::Util.render(binding, "docker_dockerfile.erb"),
                    Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::UNREF),
                    "/var", "lib", "docker", "construqt", docker.name, "Dockerfile")
                  host.result.add(Docker, Construqt::Util.render(binding, "docker_run.sh.erb"),
                    Construqt::Resources::Rights.root_0755(Construqt::Resources::Component::UNREF),
                    "/var", "lib", "docker", "construqt", docker.name, "docker_run.sh")
                end
            end



            def self.deploy_mother(host)
              []
            end

            def self.deploy_docker(host)
              [
                #Construqt::Util.render(binding, "lxc/lxc_deploy.sh.erb")
              ]
            end

            def self.deploy(host)
              # if this a mother
              return deploy_mother(host) unless Container.i_ma_the_mother?(host)
              return deploy_docker(host)
            end

            def self.render(host, docker)
              # binding.pry
              docker.result.add(Docker, Construqt::Util.render(binding, "docker_starter.sh.erb"),
                Construqt::Resources::Rights.root_0755(Construqt::Resources::Component::UNREF),
                "/root", "docker-starter.sh")
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
