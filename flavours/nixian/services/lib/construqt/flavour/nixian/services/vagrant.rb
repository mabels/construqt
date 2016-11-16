require_relative 'vagrant_file'

module Construqt
  module Flavour
    module Nixian
      module Services
        class Vagrant
          def initialize
            @cfgs = []
          end

          def add_cfg(str)
            @cfgs << str
            self
          end

          def get_cfgs
            @cfgs
          end

          def root_passwd(pwd)
            @root_passwd = pwd
            self
          end

          def get_root_password
            @root_passwd
          end

          def box(name)
            @box = name
            self
          end

          def get_box
            @box || 'ubuntu/trusty32'
          end

          def net(net)
            @net = net
            self
          end

          def get_net
            @net
          end

          def auto_config(mode = false)
            @auto_config = mode
            self
          end

          def get_auto_config
            @auto_config
          end

          def ssh_host_port(port)
            @ssh_host_port = port
            self
          end

          def get_ssh_host_port
            @ssh_host_port
          end

          def box_version(version)
            @box_version = version
            self
          end

          def get_box_version
            @box_version
          end

          def box_url(url)
            @box_url = url
            self
          end

          def get_box_url
            @box_url
          end
        end

        class VagrantImpl
          attr_reader :service_type
          def initialize
            @service_type = Vagrant
          end

          def attach_service(service)
            @service = service
          end

          def render_vagrant(host, vagrant)
            vfile = host.flavour.dialect.vagrant_factory(host, vagrant)
            vagrant.interfaces.values.map do |iface|
              if iface.cable && !iface.cable.connections.empty?
                vfile.add_link(iface.cable.connections.first.iface, iface)
              end
            end

            vfile.render
          end

          def build_config_host(host, service)
            host.region.hosts.get_hosts.select { |h| host.eq(h.mother) }.each do |vagrant|
              render_vagrant(host, vagrant)
            end

            render_vagrant(host, host)
          end
        end
      end
    end
  end
end
