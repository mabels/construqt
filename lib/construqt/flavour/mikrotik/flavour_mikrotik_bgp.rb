module Construqt
  module Flavour
    module Mikrotik

      class Bgp
        attr_accessor :delegate, :other, :cfg, :route_reflect
        attr_reader :host, :as, :default_originate, :filter, :my
        def initialize(cfg)
          @other = cfg['other']
          @my = cfg['my']
          @cfg = cfg['cfg']
          @host = cfg['host']
          @route_reflect = cfg['route_reflect']
          @as = cfg['as']
          @default_originate = cfg['default_originate']
          @filter = cfg['filter']
        end

        def self.write_filter_with_prefix(host, filter, rule, nets, in_prefix_len)
          nets.each do |ip|
            prefix_len = ""
            unless in_prefix_len.nil?
              if in_prefix_len.kind_of?(Array)
                prefix_len = " prefix-length=#{in_prefix_len.first}-#{in_prefix_len.last}"
              else
                prefix_len = " prefix-length=#{in_prefix_len}"
              end
            end
            host.result.add("add action=#{rule['rule']} chain=v#{ip.ipv4? ? '4':'6'}-#{filter.name} prefix=#{ip.to_string}#{prefix_len}", nil, "routing", "filter")
          end
        end

        def self.write_filter(host)
          Bgps.filters.each do |filter|
            v4_name="v4-#{filter.name}"
            v6_name="v6-#{filter.name}"
            host.result.add("set [ find chain=#{v4_name.inspect} ] comment=to_remove", nil, "routing", "filter")
            host.result.add("set [ find chain=#{v6_name.inspect} ] comment=to_remove", nil, "routing", "filter")
            filter.list.each do |rule|
              nets = rule['network']
              if nets.kind_of?(String)
                if rule['prefix_length']
                  write_filter_with_prefix(host, filter, rule, Construqt::Tags.ips_net(nets, Construqt::Addresses::IPV4) +
                                                 Construqt::Tags.ips_net(nets, Construqt::Addresses::IPV6), rule['prefix_length'])
                else
                  [Construqt::Tags.ips_net_per_prefix(nets, Construqt::Addresses::IPV4),
                   Construqt::Tags.ips_net_per_prefix(nets, Construqt::Addresses::IPV6)].each do |pre_family|
                    pre_family.values.each do |pre_prefix|
                      pre_prefix.each do |prefix, ip_list|
                        write_filter_with_prefix(host, filter, rule, ip_list, prefix)
                      end
                    end
                  end
                end

                #              binding.pry if nets == "OVERLAY-CT"
                #            puts ">>>>>>>>>> #{nets.map{|i| i.class.name}}"
                #                nets = IPAddress::summarize(nets)
              else
                write_filter_with_prefix(host, filter, rule, nets.ips, rule['prefix_length'])
              end
            end

            host.result.add("remove [ find comment=to_remove && (chain=#{v4_name.inspect} || chain=#{v6_name.inspect}) ]", nil, "routing", "filter")
          end
        end

        def self.set_routing_bgp_instance(host, cfg)
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
          host.result.render_mikrotik(default, cfg, "routing", "bgp", "instance")
        end

        def self.write_peer(host)
          as_s = {}
          Bgps.connections.each do |bgp|
            (bgp.rights+bgp.lefts).each do |my|
              as_s[my.as] ||= OpenStruct.new(:host => host) if my.host == host
            end
          end

          as_s.each do |as, val|
            host = val.host
            #puts "****** #{host.name}"
            digest=Digest::SHA256.hexdigest("#{host.name} #{host.id.first_ipv4.first_ipv4.to_s} #{as}")
            net = host.id.first_ipv4.first_ipv4.to_s.split('.')[0..1]
            net.push(digest[0..1].to_i(16).to_s)
            net.push(digest[-2..-1].to_i(16).to_s)
            router_id = IPAddress.parse(net.join('.')) # hack ..... achtung
            cfg = as.to_h.inject({}){|r,(k,v)| r[k.to_s]=v; r }.merge({
              "comment" => as.description,
              "name"=>"#{as.name}",
              "as" => as.num,
              "router-id" => router_id}).inject({}) {|r,p| r[p.first.to_s] = p.last; r}
            #puts ">>>#{cfg.inspect}"
            set_routing_bgp_instance(host, cfg)
          end

          #puts ">>>>>> #{as_s.keys}"
        end

        def self.header(host)
          #binding.pry if host.name == "s2b-l3-r01"
          self.write_peer(host)
          self.write_filter(host)
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
          self.host.result.render_mikrotik(default, cfg, "routing", "bgp", "peer")
        end

        def build_config(unused, unused1)
          #binding.pry
          #puts "as=>#{self.as} #{self.other.my.host.name}"
          self.other.my.address.first_ipv4 && set_routing_bgp_peer("name"=> "v4-#{self.other.my.host.name}-#{self.as.name}",
                                                                   "comment" => "v4-#{self.other.my.host.name}-#{self.as.name}",
                                                                   "instance" => "#{self.as.name}",
                                                                   "remote-as" => self.other.as.num,
                                                                   "address-families" => "ip",
                                                                   "default-originate" => self.default_originate,
                                                                   "remote-address" => self.other.my.address.first_ipv4,
                                                                   "route-reflect" => self.route_reflect,
                                                                   "use-bfd" => self.cfg.use_bfd.kind_of?(false.class) ? false : true,
                                                                   "tcp-md5-key" => self.cfg.password,
                                                                   "in-filter" => "v4-"+self.filter['in'].name,
                                                                   "out-filter" => "v4-"+self.filter['out'].name)
          self.other.my.address.first_ipv6 && set_routing_bgp_peer("name"=> "v6-#{self.other.my.host.name}-#{self.as.name}",
                                                                   "comment" => "v6-#{self.other.my.host.name}-#{self.as.name}",
                                                                   "instance" => "#{self.as.name}",
                                                                   "remote-as" => self.other.as.num,
                                                                   "address-families" => "ipv6",
                                                                   "route-reflect" => self.route_reflect,
                                                                   "remote-address" => self.other.my.address.first_ipv6,
                                                                   "use-bfd" => self.cfg.use_bfd.kind_of?(false.class) ? false : true,
                                                                   "tcp-md5-key" => self.cfg.password,
                                                                   "in-filter" => "v6-"+self.filter['in'].name,
                                                                   "out-filter" => "v6-"+self.filter['out'].name)
        end
      end
    end
  end
end
