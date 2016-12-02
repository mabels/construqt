module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Systemd
          class IpTables

            def on_add(ud, taste, iface, me)
              # binding.pry if iface.name == "etcbind-2"
#              systemd = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcSystemdNetwork::OncePerHost)
#              systemd.add(Result::SystemdService.new("construqt-docker@#{docker.name}.service")
#                  .description("docker-#{docker.name}")
#                  .type("simple")
#                  .after("docker.service")
#                  .after("network-online.target")
#                  .requires("docker.service")
#                  .requires("network-online.target")
#                  .exec_start("/bin/sh /var/lib/docker/construqt/#{docker.name}/docker_run.sh")
#                  .exec_stop("/usr/bin/docker stop -t 2 run_#{docker.name}")
#                  .exec_stop_post("/usr/bin/docker rm -f run_#{docker.name}")
#                  .wanted_by("multi-user.target"))
            end
            def activate(ctx)
              @context = ctx
              self
            end
          end
          add(Entities::IpTables, IpTables)
        end
      end
    end
  end
end
