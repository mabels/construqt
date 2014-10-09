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
        host.result.add("set [ find chain=v4-#{filter.name.inspect} ] comment=to_remove", nil, "routing", "filter")
        host.result.add("set [ find chain=v6-#{filter.name.inspect} ] comment=to_remove", nil, "routing", "filter")
        filter.list.each do |rule|
          rule['network'].ips.each do |ip|
            prefix_len = ""
            if rule['prefix_length']
              prefix_len = "prefix-length=#{rule['prefix_length'].first}-#{rule['prefix_length'].last}"
            end
            host.result.add("add action=#{rule['rule']} chain=v#{ip.ipv4? ? '4':'6'}-#{filter.name} prefix=#{ip.to_string} #{prefix_len}", nil, "routing", "filter")
          end
        end
        host.result.add("remove [ find comment=to_remove && (chain=v4-#{filter.name.inspect} || chain=v6-#{filter.name.inspect}) ]", nil, "routing", "filter")
      end
    end
    def set_routing_bgp_instance(cfg)
      default = {
        "name" => Schema.string.required,
        "as" => Schema.int.required.key,
        "router-id"=> Schema.address.required,
        "redistribute-connected" => Schema.boolean.default(true),
        "redistribute-static" => Schema.boolean.default(true), 
        "redistribute-rip" => Schema.boolean.default(false),
        "redistribute-ospf" => Schema.boolean.default(false),
        "redistribute-other-bgp" => Schema.boolean.default(false),
        "out-filter"=>Schema.identifier.default(nil), 
        "client-to-client-reflection"=>Schema.boolean.default(true),
        "ignore-as-path-len"=>Schema.boolean.default(false),
        "routing-table"=>Schema.identifier.default(nil),
        "comment"=>Schema.string.default(nil)
      }
      self.host.result.delegate.render_mikrotik(default, cfg, "routing", "bgp", "instance")
    end
    def write_peer(host)
      as_s = {}
      Bgps.connections.each do |bgp|
        as_s[bgp.left.as] ||= host if bgp.left.my.host == host
        as_s[bgp.right.as] ||= host if bgp.right.my.host == host
      end
      as_s.each do |as, host|
        #puts "****** #{host.name} #{"%x"%host.id.first_ipv4.first_ipv4.to_i} #{"%x"%as.to_i} #{"%x"%(host.id.first_ipv4.first_ipv4.to_i | as.to_i)}"
        digest=Digest::SHA256.hexdigest("#{host.name} #{host.id.first_ipv4.first_ipv4.to_s} #{as}")  
        net = host.id.first_ipv4.first_ipv4.to_s.split('.')[0..1] 
        net.push(digest[0..1].to_i(16).to_s)
        net.push(digest[-2..-1].to_i(16).to_s)
        router_id = IPAddress.parse(net.join('.')) # hack ..... achtung
        cfg = as.to_h.merge("comment" => as.description, "name"=>"#{as.name}", "as" => as.num, "router-id" => router_id).inject({}) {|r,p| r[p.first.to_s] = p.last; r}
        #puts ">>>#{cfg.inspect}"
        set_routing_bgp_instance(cfg)
      end
      #puts ">>>>>> #{as_s.keys}"
    end
    def header(host)
      #binding.pry if host.name == "s2b-l3-r01"
      write_peer(host)
      write_filter(host)
    end

    def set_routing_bgp_peer(cfg)
      default = {
        "name" => Schema.identifier.required.key,
        "instance" => Schema.identifier.required,
        "remote-address" => Schema.address.required,
        "remote-as" => Schema.int.required,
        "in-filter" => Schema.identifier.required,
        "out-filter" => Schema.identifier.required,
        "tcp-md5-key" => Schema.string.default(""),
        "nexthop-choice" => Schema.identifier.default("force-self"),
        "multihop" => Schema.boolean.default(false),
        "route-reflect" => Schema.boolean.default(false),
        "hold-time" => Schema.identifier.default("3m"),
        "ttl" => Schema.identifier.default("default"),
        "address-families" => Schema.identifier.required,
        "default-originate" => Schema.identifier.default("never"),
        "remove-private-as" => Schema.boolean.default(false),
        "as-override" => Schema.boolean.default(false),
        "passive" => Schema.boolean.default(false),
        "use-bfd" => Schema.boolean.default(true),
        "comment" => Schema.string.null
      }
      self.host.result.delegate.render_mikrotik(default, cfg, "routing", "bgp", "peer")
    end

    def build_config(unused, unused1)
      #binding.pry
      #puts "as=>#{self.as} #{self.other.my.host.name}"
      self.other.my.address.first_ipv4 && set_routing_bgp_peer("name"=> "v4-#{self.other.my.host.name}",
                           "comment" => "v4-#{self.other.my.host.name}",
                           "instance" => "#{self.as.name}", 
                           "remote-as" => self.other.as.num, 
                           "address-families" => "ip",
                           "remote-address" => self.other.my.address.first_ipv4,
                           "tcp-md5-key" => self.cfg.password, 
                           "in-filter" => "v4-"+self.filter['in'].name,
                           "out-filter" => "v4-"+self.filter['out'].name)
      self.other.my.address.first_ipv6 && set_routing_bgp_peer("name"=> "v6-#{self.other.my.host.name}" , 
                           "comment" => "v6-#{self.other.my.host.name}",
                           "instance" => "#{self.as.name}", 
                           "remote-as" => self.other.as.num, 
                           "address-families" => "ipv6",
                           "remote-address" => self.other.my.address.first_ipv6,
                           "tcp-md5-key" => self.cfg.password, 
                           "in-filter" => "v6-"+self.filter['in'].name,
                           "out-filter" => "v6-"+self.filter['out'].name)
    end
  end

end
end
end
