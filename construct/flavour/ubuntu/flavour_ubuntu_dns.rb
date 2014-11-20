module Construct
  module Flavour

    module Ubuntu
      module Dns
        def self.prefix(host, path)
        end

        def self.write_header(region, domain)
          ret = [<<OUT]
; this is a generated file do not edit!!!!!
; for #{domain.to_s}
$TTL 86400      ; 1 day
          #{domain}. IN SOA ns.#{region.network.domain}. #{region.network.contact}. (
          #{Time.now.to_i} ; serial
10000      ; refresh (2 hours 46 minutes 40 seconds)
3600       ; retry (1 hour)
604800     ; expire (1 week)
28800      ; minimum (8 hours)
)
OUT
          region.hosts.get_hosts.each do |host|
            next unless host.delegate.dns_server
            plain_adr = region.network.addresses.all.find{|i| i.name == host.name }
            unless plain_adr
              plain_adr = host.id.first_ipv6
            end

            ret << "#{domain}. 3600 IN NS #{region.network.fqdn(plain_adr.name)}."
            #if (domain == Addresses.domain)
            #  ret << "#{host.id.first_ipv6.fqdn}.  3600 IN A #{host.id.first_ipv4}" if host.id.first_ipv4
            #  ret << "#{host.id.first_ipv6.fqdn}.  3600 IN AAAA #{host.id.first_ipv6}" if host.id.first_ipv6
            #end
          end

          ret << ""
          ret.join("\n")
        end

        def self.build_config(host)
          forward = {}
          reverse = {}
          host.region.network.addresses.all.each do |address|
            name = host.region.network.fqdn(address.name)
            domain = host.region.network.domain
            forward[domain] ||= []
            address.ips.each do |ip|
              next if ip.to_i == ip.network.to_i && ((ip.ipv6? && ip.prefix < 128) || (ip.ipv4? && ip.prefix < 32))
              forward[domain] << "#{"%-42s" % "#{name}."} 3600 IN #{ip.ipv4? ? 'A' : 'AAAA'} #{ip.to_s}"
              if ip.ipv4?
                forward[domain] << "#{"ipv4-%-37s" % "#{name}."} 3600 IN A    #{ip.to_s}"
              end

              if ip.ipv6?
                forward[domain] << "#{"ipv6-%-37s" % "#{name}."} 3600 IN AAAA #{ip.to_s}"
              end

              network = host.region.network.to_network(ip.network)
              reverse[network] ||= {}
              reverse[network][ip.reverse.to_s] ||= "#{ip.reverse} 3600 IN PTR #{name}."
            end
          end

          include = {}
          forward.each do |domain, lines|
            include[domain] = "/etc/bind/tables/#{domain}.forward"
            host.result.add(self, write_header(host.region, domain), Construct::Resource::Rights::ROOT_0644, "etc/bind/tables", "#{domain}.forward")
            host.result.add(self, lines.sort.join("\n"), Construct::Resource::Rights::ROOT_0644, "etc/bind/tables", "#{domain}.forward")
          end

          reverse.each do |domain, lines|
            include[domain.rev_domains.first] = "/etc/bind/tables/#{domain}.reverse"
            host.result.add(self, write_header(host.region, domain.rev_domains.first), Construct::Resource::Rights::ROOT_0644, "etc/bind/tables", "#{domain.to_s}.reverse")
            host.result.add(self, lines.values.sort.join("\n"), Construct::Resource::Rights::ROOT_0644, "etc/bind/tables", "#{domain.to_s}.reverse")
          end

          include.each do |domain,path|
            host.result.add(self, <<DNS, Construct::Resource::Rights::ROOT_0644, "etc/bind/named.conf.local")
zone "#{domain.to_s}" {
        type master;
        file "#{path}";
        notify yes;
        allow-query { any; };
};
DNS
          end
        end
      end
    end
  end
end
