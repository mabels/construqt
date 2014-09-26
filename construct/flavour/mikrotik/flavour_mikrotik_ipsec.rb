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
        "address" => Schema.required.key,
        "secret" => Schema.required,
        "local-address" => "0.0.0.0",
        "passive" => "no",
        "port" => "500",
        "auth-method" => "pre-shared-key",
        "generate-policy" => "no",
        "policy-group" => "default",
        "exchange-mode" => "main",
        "send-initial-contact" => "yes",
        "nat-traversal" => "yes",
        "proposal-check" => "obey",
        "hash-algorithm" => "sha1",
        "enc-algorithm" => "aes-256",
        "dh-group" => "modp1536",
        "lifetime" => "1d",
        "lifebytes" => "0",
        "dpd-interval" => "2m",
        "dpd-maximum-failures" => "5"
      }
      self.host.result.render_mikrotik(default, cfg, "ip", "ipsec", "peer")
    end
    def set_ip_ipsec_policy(cfg)
      default = {
        "sa-src-address" => Schema.required.key,
        "sa-dst-address" => Schema.required.key,
        "src-address" => Schema.required,
        "dst-address" => Schema.required,
        "src-port" => "any",
        "dst-port" => "any",
        "protocol" => "all",
        "action" => "encrypt",
        "level" => "require",
        "ipsec-protocols" => "esp",
        "tunnel" => "yes",
        "proposal" => "s2b-proposal",
        "priority" => "0"
      }
      puts "#{cfg['sa-src-address'].class.name}=>#{cfg['sa-dst-address'].class.name} #{cfg['src-address'].class.name}=>#{cfg['dst-address'].class.name} #{cfg.keys}"
      self.host.result.render_mikrotik(default, cfg, "ip", "ipsec", "policy")
    end
		def build_config()
      set_ip_ipsec_peer("address" => self.other.remote.first_ipv6.to_s, "secret" => Util.password(self.cfg.password))
      set_ip_ipsec_policy("src-address" => self.my.first_ipv6.to_string, "sa-src-address" => self.remote.first_ipv6.to_s,
                          "dst-address" => self.other.my.first_ipv6.to_string, "sa-dst-address" => self.other.remote.first_ipv6.to_s)
		end
	end
end
end
end
