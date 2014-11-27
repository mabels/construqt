module Construct
  module Flavour
    module Ubuntu

      class Vrrp < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def self.header(host)
          host.result.add(self, <<GLOBAL, Construct::Resources::Rights::ROOT_0644, "etc", "keepalived", "keepalived.conf")
global_defs {
  lvs_id #{host.name}
}
GLOBAL
        end

        def build_config(host, iface)
          iface = iface.delegate
          my_iface = iface.interfaces.find{|iface| iface.host == host }
          ret = []
          ret << "vrrp_instance #{iface.name} {"
          ret << "  state MASTER"
          ret << "  interface #{my_iface.name}"
          ret << "  virtual_router_id #{iface.vrid||iface.interfaces.map{|a,b| a.priority<=>b.priority}.first}"
          ret << "  priority #{my_iface.priority}"
          ret << "  authentication {"
          ret << "        auth_type PASS"
          ret << "        auth_pass fw"
          ret << "  }"
          ret << "  virtual_ipaddress {"
          iface.address.ips.each do |ip|
            ret << "    #{ip.to_string} dev #{my_iface.name}"
          end

          ret << "  }"
          if iface.services && !iface.services.empty?
            ret << "  notify /etc/network/vrrp.#{iface.name}.sh"
            writer = host.result.etc_network_interfaces.get(iface)
            iface.services.each do |service|
              Services.get_renderer(service).interfaces(host, my_iface.name, my_iface, writer)
              Services.get_renderer(service).vrrp(host, my_iface.name, iface)
            end
          end

          ret << "}"
          host.result.add(self, ret.join("\n"), Construct::Resources::Rights::ROOT_0644, "etc", "keepalived", "keepalived.conf")
        end
      end
    end
  end
end
