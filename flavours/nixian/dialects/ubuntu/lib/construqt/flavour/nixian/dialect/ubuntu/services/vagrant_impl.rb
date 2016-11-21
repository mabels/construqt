
module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          module Services
            class VagrantImpl
              attr_reader :service_type
              def initialize
                @service_type = Construqt::Flavour::Nixian::Services::Vagrant
              end

              def attach_service(service)
                @service = service
              end

              def render_vagrant(host, vagrant)
                # vfile = host.flavour.dialect.vagrant_factory(host, vagrant)
                # vagrant.interfaces.values.map do |iface|
                #   if iface.cable && !iface.cable.connections.empty?
                #     vfile.add_link(iface.cable.connections.first.iface, iface)
                #   end
                # end
                # vfile.render
              end

              def build_config_host(host, service)
                # host.region.hosts.get_hosts.select { |h| host.eq(h.mother) }.each do |vagrant|
                #   render_vagrant(host, vagrant)
                # end
                # render_vagrant(host, host)
              end
            end
          end
        end
      end
    end
  end
end
