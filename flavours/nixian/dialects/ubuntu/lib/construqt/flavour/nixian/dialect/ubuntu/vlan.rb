require_relative 'base_device'
module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          class Vlan
            include BaseDevice
            include Construqt::Cables::Plugin::Multiple
            attr_reader :interfaces
            def initialize(cfg)
              base_device(cfg)
              @interfaces = cfg['interfaces']
            end

            def belongs_to
              return [self.host] if self.interfaces.empty? # and self.cable.connections.empty?
              return self.interfaces
            end


            def build_config(host, iface, node)
                # ip link add link eth0 name eth0.8 type vlan id 8
              up_downer = host.result_types.find_instances_from_type(Construqt::Flavour::Nixian::Services::UpDowner::OncePerHost)
              up_downer.add(iface, Tastes::Entities::Vlan.new())
              Device.build_config(host, iface, node)
            end
          end
        end
      end
    end
  end
end
