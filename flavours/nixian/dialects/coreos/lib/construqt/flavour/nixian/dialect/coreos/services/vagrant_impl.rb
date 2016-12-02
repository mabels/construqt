
require_relative './vagrant_file'
module Construqt
  module Flavour
    module Nixian
      module Dialect
        module CoreOs
          module Services
          module Vagrant
            class Factory
              attr_reader :machine
              def start(service_factory)
                @machine ||= service_factory.machine
                  .service_type(Construqt::Flavour::Nixian::Services::Vagrant::Service)
                  .depend(Construqt::Flavour::Nixian::Services::Result::Service)
              end
              def produce(host, srv_inst, ret)
                Action.new(host, srv_inst)
              end
            end

            class Action
              attr_reader :host, :service
              def initialize(host, service)
                @host = host
                @service = service
              end

              def activate(ctx)
                @context = ctx
              end

              def render_vagrant(host, service, vagrant)
                vfile = VagrantFile.new(@context, host, service, vagrant)
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
end
