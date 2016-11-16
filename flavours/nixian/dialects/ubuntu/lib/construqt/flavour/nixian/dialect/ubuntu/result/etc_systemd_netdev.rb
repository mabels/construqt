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

              def is_enable
                true
              end

              def get_skip_content
                false
              end

              def as_string
                systemd_netdev = self
                iface = @interface
                Construqt::Util.render(binding, "systemd_netdev.erb")
              end
              def as_systemd_file
                as_string
              end
              def get_command
                nil
              end
              def get_name
                "#{name}.netdev"
              end

              def commit
                @interface.host.result.add(self, self.as_string,
                  Construqt::Resources::Rights.root_0644(Construqt::Flavour::Nixian::Dialect::Ubuntu::Systemd),
                  "etc", "systemd", "network", "#{self.name}.netdev")
              end
            end

            class EtcSystemdNetdev
              attr_reader :interfaces
              def initialize
                @interfaces = {}
              end

              def get(iface)
                @interfaces[iface.name] ||= SystemdNetdev.new(iface)
              end

              def netdevs(result)
                result.host.interfaces.values.map do |iface|
                  get(iface)
                end
              end

              def commit(result)
                netdevs(result).each do |sysdev|
                  sysdev.commit
                end
              end
            end
          end
        end
      end
    end
  end
end
