module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result

            class SystemdNetdev
              def initialize(iface)
                @interface = iface
              end
              def name
                @interface.name
              end
              def kind
                if @interface.delegate.respond_to?(:tunnel_kind)
                  @interface.delegate.tunnel_kind
                else
                  @interface.delegate.clazz
                end
              end
              def tunnel_mode
                @interface.delegate.tunnel_mode if @interface.delegate.respond_to?(:tunnel_mode)
              end
              def vlan_id
                @interface.delegate.vlan_id(@interface) if @interface.delegate.respond_to?(:vlan_id)
              end
              def commit
                systemd_netdev = self
                iface = @interface
                @interface.host.result.add(self,
                  Construqt::Util.render(binding, "systemd_netdev.erb"),
                  Construqt::Resources::Rights.root_0644, "etc", "systemd", "network", "#{self.name}.netdev")
              end
            end

            class EtcSystemdNetdev
              def initialize
                @interfaces = {}
              end

              def get(iface)
                @interfaces[iface.name] ||= SystemdNetdev.new(iface)
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
