require 'digest/md5'

module Construct
module Flavour
module Mikrotik
	class Ipsec < OpenStruct
		def initialize(cfg)
			super(cfg)
		end
    def set_ip_ipsec_peer(cfg)
      default = {
        "address" => Schema.address.required.key,
        "secret" => Schema.string.required,
        "local-address" => Schema.required.address,
        "passive" => Schema.identifier.default("no"),
        "port" => Schema.int.default(500),
        "auth-method" => Schema.identifier.default("pre-shared-key"),
        "generate-policy" => Schema.identifier.default("no"),
        "policy-group" => Schema.identifier.default("default"),
        "exchange-mode" => Schema.identifier.default("main"),
        "send-initial-contact" => Schema.identifier.default("yes"),
        "nat-traversal" => Schema.identifier.default("yes"),
        "proposal-check" => Schema.identifier.default("obey"),
        "hash-algorithm" => Schema.identifier.default("sha1"),
        "enc-algorithm" => Schema.identifier.default("aes-256"),
        "dh-group" => Schema.identifier.default("modp1536"),
        "lifetime" => Schema.identifier.default("1d"),
        "lifebytes" => Schema.int.default(0),
        "dpd-interval" => Schema.identifier.default("2m"),
        "dpd-maximum-failures" => Schema.int.default(5)
      }
      self.host.result.render_mikrotik(default, cfg, "ip", "ipsec", "peer")
    end
    def set_ip_ipsec_policy(cfg)
      default = {
        "sa-src-address" => Schema.address.required.key,
        "sa-dst-address" => Schema.address.required.key,
        "src-address" => Schema.address.required,
        "dst-address" => Schema.address.required,
        "src-port" => Schema.port.default("any"),
        "dst-port" => Schema.port.default("any"),
        "protocol" => Schema.identifier.default("all"),
        "action" => Schema.identifier.default("encrypt"),
        "level" => Schema.identifier.default("require"),
        "ipsec-protocols" => Schema.identifier.default("esp"),
        "tunnel" => Schema.identifier.default("yes"),
        "proposal" => Schema.identifier.default("s2b-proposal"),
        "priority" => Schema.int.default(0)
      }
      puts "#{cfg['sa-src-address'].class.name}=>#{cfg['sa-dst-address'].class.name} #{cfg['src-address'].class.name}=>#{cfg['dst-address'].class.name} #{cfg.keys}"
      self.host.result.render_mikrotik(default, cfg, "ip", "ipsec", "policy")
    end
		def build_config()
      set_ip_ipsec_peer("address" => self.other.remote.first_ipv6.to_s, 
                        "local-address" => self.remote.first_ipv6.to_s,
                        "secret" => Util.password(self.cfg.password))
      set_ip_ipsec_policy("src-address" => self.my.first_ipv6.to_s, "sa-src-address" => self.remote.first_ipv6.to_s,
                          "dst-address" => self.other.my.first_ipv6.to_s, "sa-dst-address" => self.other.remote.first_ipv6.to_s)
		end
	end
end
end
end
