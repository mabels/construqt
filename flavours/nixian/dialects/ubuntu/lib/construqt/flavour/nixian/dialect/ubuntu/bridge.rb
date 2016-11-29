require_relative 'base_device'

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu


          class Bridge
            include BaseDevice
            include Construqt::Cables::Plugin::Multiple
            attr_reader :interfaces
            def initialize(cfg)
              base_device(cfg)
              @interfaces = cfg['interfaces']
            end

            #def up_down_member(iface)
            #  [Tastes::Entities::BridgeMember.new(self.name, iface.name)]
            #end

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
              up_downer = host.result_types.find_instances_from_type(Construqt::Flavour::Nixian::Services::UpDowner::OncePerHost)
              up_downer.add(iface, Tastes::Entities::Bridge.new(iface.name))
              Device.build_config(host, iface, node)
            end
          end
        end
      end
    end
  end
end
