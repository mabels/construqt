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

              def as_string
                systemd_network = self
                Construqt::Util.render(binding, "systemd_network.erb")
              end
              def as_systemd_file
                as_string
              end
              def get_command
                nil
              end
              def get_name
                "#{name}.network"
              end

              def commit
                @interface.host.result.add(self, as_string,
                  Construqt::Resources::Rights.root_0644(Construqt::Flavour::Nixian::Dialect::Ubuntu::Systemd),
                  "etc", "systemd", "network", "#{self.name}.network")
              end

            end

            class EtcSystemdNetwork
              def initialize
                @interfaces = {}
              end

              def get(iface)
                @interfaces[iface.name] ||= SystemdNetwork.new(iface)
              end

              def networks(result)
                result.host.interfaces.values.map do |iface|
                  get(iface)
                end
              end

              def commit(result)
                networks(result).each do |network|
                  network.commit
                end
              end
            end
          end
        end
      end
    end
  end
end
