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

            def up_member(iface)
              []
            end
            def down_member(iface)
              []
            end

            def belongs_to
              return [self.host] if self.interfaces.empty? # and self.cable.connections.empty?
              return self.interfaces
            end

            def split_name(iface)
              vlan = iface.name.split('.')
              throw "vlan name not valid if.# => #{iface.name}" if vlan.length != 2 ||
                !vlan.first.match(/^[0-9a-zA-Z]+$/) ||
                !vlan.last.match(/^[0-9]+/) ||
                !(1 <= vlan.last.to_i && vlan.last.to_i < 4096)
              vlan
            end
            def vlan_id(iface)
              split_name(iface).last
            end
            def dev_name(iface)
              split_name(iface).first
            end

            def build_config(host, iface, node)
              iface.on_iface_up_down do |writer, ifname|
                # ip link add link eth0 name eth0.8 type vlan id 8
                writer.lines.up("ip link add link #{dev_name(iface)} name #{iface.name} type vlan id #{vlan_id(iface)}")
                writer.lines.down("ip link delete dev #{iface.name} type vlan id #{vlan_id(iface)}")
              end
              Device.build_config(host, iface, node)
            end
          end
        end
      end
    end
  end
end
