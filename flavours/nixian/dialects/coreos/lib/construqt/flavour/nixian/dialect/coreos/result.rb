require 'yaml'
require "base64"
module Construqt
  module Flavour
    module Nixian
      module Dialect
        module CoreOs
          class CloudInit
            def initialize(host)
              @host = host
              @yaml = {
                'ssh_authorized_keys' => [],
                'write_files' => [],
                'coreos' => {
                  'units' => []
                }
              }
              host.region.users.get_authorized_keys(host.delegate).each do |pk|
                add_ssh_pubkey(pk)
              end
            end

            def add_ssh_pubkey(pub)
              @yaml['ssh_authorized_keys'] << pub
            end

            def add_file(obj)
              @yaml['write_files'] << obj
            end

            def add_units(sysrv)
              tmp = { 'name' => sysrv.get_name }
              sysrv.is_enable && tmp['enable'] = true
              sysrv.get_command && tmp['command'] = sysrv.get_command
              unless sysrv.get_skip_content
                tmp['content'] = sysrv.as_systemd_file.strip+"\n"
              end
              @yaml['coreos']['units'] << tmp
            end

            def write
              Util.write_str(@host.region, "#cloud-config\n\n" + YAML.dump(@yaml), @host.name, 'coreos-cloud-config')
            end
          end

          class Result
            attr_reader :ures
            def initialize(host)
              @ures = Construqt::Flavour::Nixian::Dialect::Ubuntu::Result.new(host)
            end

            def host
              @ures.host
            end

            def add(block, digest, *path)
              @ures.add(block, digest, *path)
            end

            def add_component(component)
              @ures.add_component(component)
            end

            def etc_network_iptables
              @ures.etc_network_iptables
            end

            def etc_network_interfaces
              @ures.etc_network_interfaces
            end

            # def prefix_cloud_config(fd)
            #   akeys = host.region.users.get_authorized_keys(host.delegate)
            #   out['ssh_authorized_keys'] = akeys
            #   out['coreos'] = { }
            #   out['write_files'] = [
            #     {
            #       "path"=> "/home/core/deployer.sh",
            #       "permissions"=> "0600",
            #       "owner"=> "root",
            #       "content"=> IO.read(deployer_sh)
            #     }
            #   ]
            #   Util.write_str(host.region, "#cloud-config\n\n"+YAML.dump(out), host.name, 'coreos-cloud-config')
            # end

            def write_file(ccc, host, fname, block)
              return if block.empty?
              if host.files
                return [] if host.files.find do |file|
                  file.path == fname && file.is_a?(Construqt::Resources::SkipFile)
                end
              end

              text = block.flatten.select { |i| !(i.nil? || i.strip.empty?) }.join("\n")
              unless text.empty?
                Util.write_str(host.region, text, host.name, fname)
              end

              return if block.right.component == Construqt::Flavour::Nixian::Dialect::Ubuntu::Systemd
              ccc.add_file({
                "path"=> File.join("", fname),
                "permissions"=> block.right.right,
                "owner"=> block.right.owner,
                "encoding" => "base64",
                "content"=> Base64.encode64(text)
              })
            end

            def commit
              add(self, Construqt::Util.render(binding, "modules.conf.erb"), Construqt::Resources::Rights::root_0644, "etc", "modules-load.d", "construqt.conf")

              # binding.pry
              add(Construqt::Flavour::Nixian::Dialect::Ubuntu::Result::EtcNetworkIptables,
                  @ures.etc_network_iptables.commitv4,
                  Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::FW4),
                  'etc', 'network', 'iptables.cfg')
              add(Construqt::Flavour::Nixian::Dialect::Ubuntu::Result::EtcNetworkIptables,
                  @ures.etc_network_iptables.commitv6,
                  Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::FW6),
                  'etc', 'network', 'ip6tables.cfg')
              # add(Construqt::Flavour::Nixian::Dialect::Ubuntu::Result::EtcNetworkInterfaces,
              #     @ures.etc_network_interfaces.commit,
              #     Construqt::Resources::Rights.root_0644,
              #     'etc', 'network', 'interfaces')

              # binding.pry
              Construqt::Flavour::Nixian::Dialect::Ubuntu::Docker.write_deployers(host)

              ccc = CloudInit.new(host)
              @ures.etc_systemd_netdev.commit(@ures) # just for debugging
              @ures.etc_systemd_netdev.netdevs(@ures).each do |netdev|
                ccc.add_units(netdev)
              end

              @ures.etc_systemd_network.commit(@ures) # just for debugging
              @ures.etc_systemd_network.networks(@ures).each do |network|
                ccc.add_units(network)
              end


              modules_service = Construqt::Flavour::Nixian::Dialect::Ubuntu::Result::SystemdService
                .new(@ures, "systemd-modules-load.service")
                .skip_content
                .command("restart")
              ccc.add_units(modules_service)




              @ures.results.each do |fname, block|
                if block.right.component == Construqt::Flavour::Nixian::Dialect::Ubuntu::Systemd
                  ccc.add_units(block.clazz)
                else
                  write_file(ccc, host, fname, block)
                end
              end

              # @ures.each do |fname, block|
              #     if block.clazz.respond_to?(:belongs_to_mother?) && !block.clazz.belongs_to_mother?
              #         write_file(ccc, host, fname, block)
              #     end

              # end

              ccc.write
            end
          end
        end
      end
    end
  end
end

#
#                             host.interfaces.values.each do |iface|
#                               next unless iface.clazz == 'bridge'
#                               c_docker = Construqt::Flavour::Nixian::Dialect::Ubuntu::Result::SystemdService.new(self, "construqt-#{iface.name}-docker.service")
#                               c_docker.description("Construqt Docker Network up script")
#                               c_docker.after("docker.service")
#                               c_docker.type("oneshot")
#                               c_docker.exec_start("/etc/network/#{iface.name}-docker-up.sh")
#                               c_docker.wanted_by("basic.target")
#                               ccc.add_units(c_docker)
#                               docker_up = Construqt::Util.render(binding, "docker_up.erb")
#                               # binding.pry
#                               add(self.class, docker_up, Construqt::Resources::Rights.root_0755, 'etc', 'network', "#{iface.name}-docker-up.sh")
#                               # writer = host.result.etc_network_interfaces.get(iface, iface.name)
#                               # writer.lines.up("ip link set mtu #{mtu || iface.delegate.mtu} dev #{ifname} up")
#                               # writer.lines.down("ip link set dev #{ifname} down")
#                               # docker network rm br169
#                               # docker network create --driver=bridge --gateway=169.254.200.1 --subnet=169.254.200.0/24 --gateway=fd00::1 --subnet=fd00::/64 br169
#                               #
#                               #                             docker network create --driver=bridge --gateway=169.254.200.1 --subnet=169.254.200.0/24 br169
#                               #                             docker run  --net=br169 --ip=169.254.200.200 busybox  ifconfi
# # #                            vips-eu-0 ~ # docker ps -q | xargs docker inspect --format '{{.State.Pid}}'
# # 3722
# # #vips-eu-0 ~ # ip link set netns 3722 dev lion-int
# #
# # vips-eu-0 ~ # nsenter -t 3722 -n ip a a 169.254.210.200/24 dev lion-int
# # vips-eu-0 ~ # nsenter -t 3722 -n  ip link set lion-int up
# # vips-eu-0 ~ # nsenter -t 3722 -n  ip r a 0.0.0.0/0 via 169.254.210.1
# # --opt=com.docker.network.bridge.enable_ip_masquerade=false \
# # --opt=com.docker.network.bridge.name=br169 \
#
#                             end

#
#                             c_up = Construqt::Flavour::Nixian::Dialect::Ubuntu::Result::SystemdService.new(self, "construqt-network-up.service")
#                             c_up.description("Construqt Network up script")
#                             c_up.before("network.target")
#                             c_up.type("oneshot")
#                             c_up.exec_start("/etc/network/network_up.sh")
#                             c_up.wanted_by("basic.target")
#                             ccc.add_units(c_up)
#                             c_down = Construqt::Flavour::Nixian::Dialect::Ubuntu::Result::SystemdService.new(self, "construqt-network-down.service")
#                             c_down.description("Construqt Network up script")
#                             c_down.before("shutdown.target")
#                             c_down.type("oneshot")
#                             c_down.exec_start("/etc/network/network_down.sh")
#                             c_down.wanted_by("shutdown.target")
#                             ccc.add_units(c_down)
