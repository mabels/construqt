
require_relative './vagrant_file'
module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          module Services
            class VagrantFactory
              attr_reader :machine
              def initialize(service_factory)
                @machine = service_factory.machine
                  .service_type(Construqt::Flavour::Nixian::Services::Vagrant)
              end
              def produce(host, srv_inst, ret)
                VagrantAction.new(host)
              end
            end

            class VagrantAction
              attr_reader :host, :service
              def initialize(host)
                @host = host
              end

              def attach_service(service)
                @service = service
              end

              def render_vagrant(host, service, vagrant)
                vfile = VagrantFile.new(host, service, vagrant)
                vagrant.interfaces.values.map do |iface|
                  if iface.cable && !iface.cable.connections.empty?
                    vfile.add_link(iface.cable.connections.first.iface, iface)
                  end
                end
                vfile.render
              end

              def build_config_host #(host, service)
                host.region.hosts.get_hosts.select { |h| host.eq(h.mother) }.each do |vagrant|
                  render_vagrant(host, service, vagrant)
                end
                render_vagrant(host, service, host)
              end
            end
          end
        end
      end
    end
  end
end
