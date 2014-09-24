module Construct
module Flavour
module Mikrotik

	class Interface < OpenStruct
		def initialize(cfg)
			super(cfg)
		end
		def add_ip(ip)
      cfg = {
        "address" => ip.to_string,
        "interface" => self.name
      }
      if ip.ipv6? 
        default = {
          "address" => Schema.required,
          "interface" => Schema.required,
          "advertise" => "no",
          "comment" => Schema.required.key
        }
        cfg['comment'] = "#{cfg['interface']}-#{cfg['address']}"
        self.host.result.render_mikrotik(default, cfg, "ipv6", "address")
      else
        default = {
          "address" => Schema.required,
          "interface" => Schema.required,
          "comment" => Schema.required.key
        }
        cfg['comment'] = "#{cfg['interface']}-#{cfg['address']}"
        self.host.result.render_mikrotik(default, cfg, "ip", "address")
      end
		end
		def add_route(rt)
      throw "dst via mismatch" unless rt.dst.ipv6? == rt.via.ipv6? or rt.dst.ipv4? == rt.via.ipv4?
      cfg = {
        "dst-address" => rt.dst.to_string,
        "gateway" => rt.via.to_s,
      }
      default = {
        "dst-address" => Schema.required,
        "gateway" => Schema.required,
        "comment" => Schema.required.key
      }
      cfg['comment'] = "#{cfg['dst-address']} via #{cfg['gateway']}"
      if rt.dst.ipv6? 
        self.host.result.render_mikrotik(default, cfg, "ipv6", "route")
      else
        self.host.result.render_mikrotik(default, cfg, "ip", "route")
      end
		end
		def build_config(host)
			name = File.join(host.name, "interface", "device")
			ret = []
			ret += self.clazz.build_config(host, self)	
			if !(self.address.nil? || self.address.ips.empty?)
				self.address.ips.each do |ip|
					ret += add_ip(ip)
				end
				self.address.routes.each do |rt|
					ret += add_route(rt)
				end
			end
			ret
		end
	end
end
end
end
