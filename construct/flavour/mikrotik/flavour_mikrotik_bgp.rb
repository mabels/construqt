require 'digest/sha1'
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
        "name" => Schema.required,
        "as" => Schema.required.key,
        "router-id"=> Schema.required,
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
        puts "****** #{host.name} #{"%x"%host.id.first_ipv4.first_ipv4.to_i} #{"%x"%as.to_i} #{"%x"%(host.id.first_ipv4.first_ipv4.to_i | as.to_i)}"
        digest=Digest::SHA256.hexdigest("#{host.name} #{host.id.first_ipv4.first_ipv4.to_s} #{as}")  
        net = host.id.first_ipv4.first_ipv4.to_s.split('.')[0..1] 
        net.push(digest[0..1].to_i(16).to_s)
        net.push(digest[-2..-1].to_i(16).to_s)
        router_id = net.join('.') # hack ..... achtung
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
        "name" => Schema.required.key,
        "instance" => Schema.required,
        "remote-address" => Schema.required,
        "remote-as" => Schema.required,
        "in-filter" => Schema.required,
        "out-filter" => Schema.required,
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
