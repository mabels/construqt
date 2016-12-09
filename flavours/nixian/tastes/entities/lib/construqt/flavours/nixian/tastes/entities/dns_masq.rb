

module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Entities
          class DnsMasq
            attr_reader :iface, :cfg
            def initialize(iface, cfg)
              @iface = iface
              @cfg = cfg
            end

            def start_cmd
              [
                 "dnsmasq",
                 "-u dnsmasq",
                 "--strict-order",
                 "--pid-file=/run/#{iface.name}-dnsmasq.pid",
                 "--no-daemon",
                 "--conf-file=",
                 "--listen-address #{iface.address.first_ipv4}",
                 "--domain=#{cfg.get_domain}",
                 "--host-record=#{iface.host.name}.#{cfg.get_domain}.,#{iface.address.first_ipv4}",
                 "--dhcp-range #{cfg.get_start},#{cfg.get_end}",
                 "--dhcp-lease-max=253",
                 "--dhcp-no-override",
                 "--except-interface=lo",
                 "--interface=#{iface.name}",
                 "--dhcp-leasefile=/var/lib/misc/dnsmasq.#{iface.name}.leases",
                 "--dhcp-authoritative"
               ]
             end
          end
          add(DnsMasq)
        end
      end
    end
  end
end
