module Construct
  module Flavour
    module Ubuntu

      class Bgp < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def prefix(host, path)
          #      binding.pry
          ret = <<BGP
log syslog { debug, trace, info, remote, warning, error, auth, fatal, bug };
router id #{self.host.id.first_ipv4.first_ipv4.to_s};
protocol device {
}
protocol direct {
}
protocol kernel {
        learn;
        persist;                # Don't remove routes on bird shutdown
        scan time 20;           # Scan kernel routing table every 20 seconds
        export all;             # Default is export none
}
protocol static {
}

BGP
          if path.include?("bird6.conf")
            mode = OpenStruct.new :net_clazz => IPAddress::IPv6, :filter => lambda {|ip| ip.ipv6? }
          else
            mode = OpenStruct.new :net_clazz => IPAddress::IPv4, :filter => lambda {|ip| ip.ipv4? }
          end

          Bgps.filters.each do |filter|
            ret = ret + "filter filter_#{filter.name} {\n"
            filter.list.each do |rule|
              nets = rule['network']
              if nets.kind_of?(String)
                nets = Construct::Tags.find(nets, mode.net_clazz)
                #            puts ">>>>>>>>>> #{nets.map{|i| i.class.name}}"
                nets = IPAddress::summarize(nets)
              else
                nets = nets.ips
              end

              nets.each do |ip|
                next unless mode.filter.call(ip)
                ip_str = ip.to_string
                if rule['prefix_length']
                  ip_str = "#{ip.to_string}{#{rule['prefix_length'].first},#{rule['prefix_length'].last}}"
                end

                ret = ret + "  if net ~ [ #{ip_str} ] then { print \"#{rule['rule']}:\",net; #{rule['rule']}; }\n"
              end
            end

            ret = ret + "}\n\n"
          end

          ret
        end

        def build_bird_conf
          if self.my.address.first_ipv4 && self.other.my.address.first_ipv4
            self.my.host.result.add(self, <<BGP, Construct::Resource::Rights::ROOT_0644, "etc", "bird", "bird.conf")
protocol bgp #{Util.clean_bgp(self.my.host.name)}_#{Util.clean_bgp(self.other.host.name)} {
        description "#{self.my.host.name} <=> #{self.other.host.name}";
        direct;
        next hop self;
            #{self.as == self.other.as ? '' : '#'}rr client;
        local #{self.my.address.first_ipv4} as #{self.as.num};
        neighbor #{self.other.my.address.first_ipv4}  as #{self.other.as.num};
        password "#{Util.password(self.cfg.password)}";
        import #{self.filter['in'] ? "filter filter_"+self.filter['in'].name : "all"};
        export #{self.filter['out'] ? "filter filter_"+self.filter['out'].name : "all"};
}
BGP
          end
        end

        def build_bird6_conf
          #      binding.pry
          if self.my.address.first_ipv6 && self.other.my.address.first_ipv6
            self.my.host.result.add(self, <<BGP, Construct::Resource::Rights::ROOT_0644, "etc", "bird", "bird6.conf")
protocol bgp #{Util.clean_bgp(self.my.host.name)}_#{Util.clean_bgp(self.other.host.name)} {
        description "#{self.my.host.name} <=> #{self.other.host.name}";
        direct;
        next hop self;
            #{self.as == self.other.as ? '' : '#'}rr client;
        local as #{self.as.num};
        neighbor #{self.other.my.address.first_ipv6}  as #{self.other.as.num};
        password "#{Util.password(self.cfg.password)}";
        import #{self.filter['in'] ? "filter filter_"+self.filter['in'].name : "all"};
        export #{self.filter['out'] ? "filter filter_"+self.filter['out'].name : "all"};
}
BGP
          end
        end

        def build_config(unused, unused1)
          build_bird_conf
          build_bird6_conf
        end
      end
    end
  end
end
