module Construct
module Flavour
module Ubuntu

  class Vrrp < OpenStruct
    def initialize(cfg)
      super(cfg)
    end
    def prefix(host, path)
      ret =<<GLOBAL
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
      ret << "  virtual_router_id #{iface.vrid}"
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
      ret << "}"
      host.result.add(self, ret.join("\n"), Construct::Resource::Rights::ROOT_0644, "etc", "keepalived", "keepalived.conf")
    end
  end

end
end
end
