module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu

          class Vlan < OpenStruct
            include Construqt::Cables::Plugin::Multiple
            def initialize(cfg)
              super(cfg)
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


            def build_config(host, iface, node)
              vlan = iface.name.split('.')
              throw "vlan name not valid if.# => #{iface.name}" if vlan.length != 2 ||
                !vlan.first.match(/^[0-9a-zA-Z]+$/) ||
                !vlan.last.match(/^[0-9]+/) ||
                !(1 <= vlan.last.to_i && vlan.last.to_i < 4096)

              iface.on_iface_up_down do |writer, ifname|
                # ip link add link eth0 name eth0.8 type vlan id 8
                writer.lines.up("ip link add link #{vlan.first} name #{iface.name} type vlan id #{vlan.last}")
                writer.lines.down("ip link delete dev #{iface.name} type vlan id #{vlan.last}")
              end
              Device.build_config(host, iface, node)
            end
          end
        end
      end
    end
  end
end
