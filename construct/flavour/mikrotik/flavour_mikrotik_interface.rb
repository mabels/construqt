module Construct
module Flavour
module Mikrotik

  class Interface < OpenStruct
    def initialize(cfg)
      super(cfg)
    end
    def render_ip(ip)
      cfg = {
        "address" => ip,
        "interface" => self.name
      }
      if ip.ipv6? 
        default = {
          "address" => Schema.addrprefix.required,
          "interface" => Schema.identifier.required,
          "advertise" => Schema.boolean.default(false),
          "comment" => Schema.string.required.key
        }
        cfg['comment'] = "#{cfg['interface']}-#{cfg['address']}-CONSTRUCT"
        #puts ">>>>>>>> #{cfg.inspect}"
        self.host.result.delegate.render_mikrotik(default, cfg, "ipv6", "address")
      else
        default = {
          "address" => Schema.addrprefix.required,
          "interface" => Schema.identifier.required,
          "comment" => Schema.string.required.key
        }
        cfg['comment'] = "#{cfg['interface']}-#{cfg['address']}-CONSTRUCT"
        self.host.result.delegate.render_mikrotik(default, cfg, "ip", "address")
      end
    end
    def render_route(rt)
      throw "dst via mismatch #{rt}" if rt.type.nil? and !(rt.dst.ipv6? == rt.via.ipv6? or rt.dst.ipv4? == rt.via.ipv4?)
      cfg = {
        "dst-address" => rt.dst,
        "gateway" => rt.via,
      }
      if rt.type.nil?
        cfg['gateway'] = rt.via 
      else
        cfg['type'] = rt.type
      end
      cfg['distance'] = rt.metric if rt.metric
      default = {
        "dst-address" => Schema.network.required,
        "gateway" => Schema.address,
        "type" => Schema.identifier,
        "distance" => Schema.int,
        "comment" => Schema.string.required.key
      }
      cfg['comment'] = "#{cfg['dst-address']} via #{cfg['gateway']} CONSTRUCT"
      if rt.dst.ipv6? 
        self.host.result.delegate.render_mikrotik(default, cfg, "ipv6", "route")
      else
        self.host.result.delegate.render_mikrotik(default, cfg, "ip", "route")
      end
    end
    def build_config(host, iface)
      name = File.join(host.name, "interface", "device")
      ret = []
      ret += self.clazz.build_config(host, iface||self)  
      if !(self.address.nil? || self.address.ips.empty?)
        #binding.pry
        self.address.ips.each do |ip|
          ret += render_ip(ip)
        end
        self.address.routes.each do |rt|
          ret += render_route(rt)
        end
      end
      ret
    end
  end
end
end
end
