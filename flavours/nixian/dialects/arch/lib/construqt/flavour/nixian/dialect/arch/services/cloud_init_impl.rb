require 'yaml'
require "base64"

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Arch
          module Services
            module CloudInit
              class Service
              end

              class Action
              end

              class OncePerHost

                def initialize
                  @yaml = {
                    'users' => [],
                    'write_files' => [],
                    'runcmd' => []
                  }
                end

                attr_reader :host
                def attach_host(host)
                  @host = host
                end

                def activate(ctx)
                  @context = ctx
                end


                def add_file(obj)
                  @yaml['write_files'] << obj
                end

                def add_units(sysrv)
                  return
                  tmp = {
                    'name' => sysrv.get_name ,
                  }
                  sysrv.is_enable && tmp['enable'] = true
                  sysrv.get_command && tmp['command'] = sysrv.get_command
                  unless sysrv.get_skip_content
                    tmp['content'] = sysrv.as_systemd_file.strip+"\n"
                  end
                  if !sysrv.drop_ins.empty?
                    tmp['drop-ins'] = []
                    sysrv.drop_ins.each do |name, drop_in|
                      tmp['drop-ins'].push({
                          "name" => name,
                          "content" => drop_in.as_systemd_file.strip+"\n"
                      })
                    end
                  end

                  @yaml['coreos']['units'] << tmp
                end

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

                  #return if block.right.component == Construqt::Flavour::Nixian::Dialect::Ubuntu::Systemd
                  ccc.add_file({
                    "path"=> File.join("", fname),
                    "permissions"=> block.right.right,
                    "owner"=> block.right.owner,
                    "encoding" => "base64",
                    "content"=> Base64.encode64(text)
                  })
                end

                def write
                  Util.write_str(@host.region, "#cloud-config\n\n" + YAML.dump(@yaml), @host.name, 'construqt-cloud-config')
                end

                def commit
                  @yaml['users'].push({
                    'name' => 'root',
                    'ssh_authorized_keys' => host.region.users.get_authorized_keys(host)
                  })

                  result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)

                  etc_systemd_netdev = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcSystemdNetdev::OncePerHost)
                  etc_systemd_netdev.netdevs.each do |netdev|
                    add_units(netdev)
                  end

                  etc_systemd_network = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcSystemdNetwork::OncePerHost)
                  etc_systemd_network.networks.each do |network|
                    add_units(network)
                  end

                  modules_service = Construqt::Flavour::Nixian::Services::EtcSystemdService::SystemdService
                    .new("systemd-modules-load.service")
                    .skip_content
                    .command("restart")
                  add_units(modules_service)
                  @yaml['runcmd'].push(["systemctl", "enable", "modules_service.get_name" ])

                  etc_systemd_service = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcSystemdService::OncePerHost)
                  etc_systemd_service.services.values.each do |service|
                    add_units(service)
                    @yaml['runcmd'].push(["systemctl", "enable", service.get_name ])
                    @yaml['runcmd'].push(["systemctl", "start", "--no-block", service.get_name ])
                  end

                  result.results.each do |fname, block|
                    write_file(self, host, fname, block)
                  end

                  # @ures.each do |fname, block|
                  #     if block.clazz.respond_to?(:belongs_to_mother?) && !block.clazz.belongs_to_mother?
                  #         write_file(ccc, host, fname, block)
                  #     end

                  # end

                  write
                end
              end

              class Factory
                attr_reader :machine
                def start(service_factory)
                  @machine ||= service_factory.machine
                    .service_type(Service)
                    .result_type(OncePerHost)
                    .require(Construqt::Flavour::Nixian::Services::Result::Service)
                end

                def produce(host, srv_ins, ret)
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
