module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu


          class Bridge < OpenStruct
            include Construqt::Cables::Plugin::Multiple
            def initialize(cfg)
              super(cfg)
            end

            def up_member(iface)
              ["brctl addif #{self.name} #{iface.name}"]
            end

            def down_member(iface)
              ["brctl delif #{self.name} #{iface.name}"]
            end

            # def belongs_to
            #   return [self.host] if self.interfaces.empty? # and self.cable.connections.empty?
            #   # binding.pry
            #   # return self.interfaces +
            #   #   self.cable.connections.select do |i|
            #   #     i.iface.host.mother == self.host
            #   #   end.map{ |i| i.iface }
            #   return self.interfaces
            # end

            def build_config(host, iface, node)
              # binding.pry if host.name == "kuckpi"
              # unless iface.interfaces.empty?
              #   port_list = iface.interfaces.map { |i| i.name }.join(" ")
              #   host.result.etc_network_interfaces.get(iface).lines.add("bridge_ports #{port_list}")
              # else
              host.result.etc_network_interfaces.get(iface).lines.add("bridge_ports none")
              iface.on_iface_up_down do |writer, ifname|
                writer.lines.up("brctl addbr #{ifname}")
                writer.lines.down("brctl delbr #{ifname}")
              end
              Device.build_config(host, iface, node)
            end
          end
        end
      end
    end
  end
end
