module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result

            class SystemdNetwork
              attr_reader :interface
              def initialize(iface)
                @interface = iface
              end

              def name
                @interface.name
              end

              def tunnels
                inode = @interface.host.interface_graph.node_from_ref(@interface)
                ret = inode.children.select{|link| link.link.ref.clazz == "tunnel"}.map{|i| i.link.ref }
                # binding.pry if ret.length > 0 and @interface.host.name == "fanout-de"
                ret
              end

              def vlans
                return [] if @interface.clazz != "device"
                inode = @interface.host.interface_graph.node_from_ref(@interface)
                inode.children.select{|link| link.link.ref.clazz == "vlan"}.map{|i| i.link.ref }
              end

              def bridges
                inode = @interface.host.interface_graph.node_from_ref(@interface)
                #inode.children.select{|link| link.link.ref.clazz == "bridge"}.map{|i| i.link.ref }
                inode.parents.select{|link| link.link.ref.clazz == "bridge"}.map{ |i| i.link.ref }
              end

              def commit
                #binding.pry if @interface.host.name == "fanout-de" and @interface.name == "eth0"
                systemd_network = self
                @interface.host.result.add(self,
                  Construqt::Util.render(binding, "systemd_network.erb"),
                  Construqt::Resources::Rights.root_0644, "etc", "systemd", "network", "#{self.name}.network")
              end

            end

            class EtcSystemdNetwork
              def initialize
                @interfaces = {}
              end

              def get(iface)
                @interfaces[iface.name] ||= SystemdNetwork.new(iface)
              end

              def commit(result)
                result.host.interfaces.values.each do |iface|
                  get(iface).commit
                end
              end
            end
          end
        end
      end
    end
  end
end
