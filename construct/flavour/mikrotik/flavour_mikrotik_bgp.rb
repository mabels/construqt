module Construct
module Flavour
module Mikrotik

	class Bgp < OpenStruct
		def initialize(cfg)
			super(cfg)
		end
    
    def write_filter(host)
      Bgps.filters.each do |filter|
        host.result.add("set [ find chain=#{filter.name.inspect} ] comment=to_remove", nil, "routing", "filter")
        filter.list.each do |rule|
          rule['network'].ips.each do |ip|
            prefix_len = ""
            if rule['prefix_length']
              prefix_len = "prefix-length=#{rule['prefix_length'].first}-#{rule['prefix_length'].last}"
            end
            host.result.add("add action=#{rule['rule']} chain=#{filter.name} prefix=#{ip.to_string} #{prefix_len}", nil, "routing", "filter")
          end
        end
        host.result.add("remove [ find comment=to_remove && chain=#{filter.name.inspect} ]", nil, "routing", "filter")
      end
    end
    def set_routing_bgp_instance(cfg)
      default = {
        "name" => nil,
        "as" => nil,
        "router-id"=> nil,
        "redistribute-connected" => "yes",
        "redistribute-static" => "yes", 
        "redistribute-rip" => "yes",
        "redistribute-ospf" => "yes",
        "redistribute-other-bgp" => "no",
        "out-filter"=>"", 
        "client-to-client-reflection"=>"yes",
        "ignore-as-path-len"=>"no",
        "routing-table"=>""
      }
      self.host.result.render_mikrotik(default, cfg, "routing", "bgp", "instance")
    end
    def write_peer(host)
      as_s = {}
      Bgps.connections.each do |bgp|
        as_s[bgp.left.as] ||= host if bgp.left.my.host == host
        as_s[bgp.right.as] ||= host if bgp.right.my.host == host
      end
      as_s.each do |as, host|
        puts "****** #{host.name}"
        router_id = IPAddress::IPv4::parse_u32(host.id.first_ipv4.first_ipv4.to_i | as.to_i, 32).to_s # hack ..... achtung
        set_routing_bgp_instance("name"=>"AS#{as}", "as" => as.to_s, "router-id" => router_id)   
      end
      puts ">>>>>> #{as_s.keys}"
    end
    def once(host)
      write_peer(host)
      write_filter(host)
    end

    def set_routing_bgp_peer(cfg)
      default = {
        "name" => nil,
        "instance" => nil,
        "remote-address" => nil,
        "remote-as" => nil,
        "in-filter" => nil,
        "out-filter" => nil,
        "tcp-md5-key" => "\"\"",
        "nexthop-choice" => "force-self",
        "multihop" => "no",
        "route-reflect" => "no",
        "hold-time" => "3m",
        "ttl" => "default",
        "address-families" => "ipv6",
        "default-originate" => "never",
        "remove-private-as" => "no",
        "as-override" => "no",
        "passive" => "no",
        "use-bfd" => "yes",
      }
      self.host.result.render_mikrotik(default, cfg, "routing", "bgp", "peer")
    end

		def build_config()
      #binding.pry
      puts "as=>#{self.as} #{self.other.my.host.name}"
      set_routing_bgp_peer("name"=> "v6-#{self.other.my.host.name}" , 
                           "instance" => "AS#{self.as}" , 
                           "remote-as" => self.other.as, 
                           "remote-address" => self.other.my.address.first_ipv6.to_s,
                           "tcp-md5-key" => self.cfg.password, 
                           "in-filter" => self.filter['in'].name,
                           "out-filter" => self.filter['out'].name)
		end
	end

end
end
end
