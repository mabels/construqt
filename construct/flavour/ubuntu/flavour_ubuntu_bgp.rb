module Construct
module Flavour
  module Ubuntu

  class Bgp < OpenStruct
    def initialize(cfg)
      super(cfg)
    end
    def prefix(path)
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
#binding.pry unless path.kind_of?(String)
      ipv6 = path.include?("bird6.conf")
      Bgps.filters.each do |filter|
        ret = ret + "filter filter_#{filter.name} {\n"
        filter.list.each do |rule|
          rule['network'].ips.each do |ip|
            next unless ip.ipv6? == ipv6
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
         self.my.host.result.add(self, <<BGP, Ubuntu.root, "etc", "bird", "bird.conf")
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
         self.my.host.result.add(self, <<BGP, Ubuntu.root, "etc", "bird", "bird6.conf")
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
