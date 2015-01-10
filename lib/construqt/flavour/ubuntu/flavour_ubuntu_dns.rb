module Construqt
  module Flavour
    module Ubuntu
      module Dns

        def self.write_header(dns_server_conf, region, domain)
          ret = [<<OUT]
; this is a generated file do not edit!!!!!
; for #{domain.to_s}
$TTL 86400      ; 1 day
#{domain}. IN SOA #{dns_server_conf.nameservers.first||"ns.#{host.region.network.domain}"}. #{region.network.contact}. (
          #{dns_server_conf.serial||Time.now.to_i} ; serial
10000      ; refresh (2 hours 46 minutes 40 seconds)
3600       ; retry (1 hour)
604800     ; expire (1 week)
28800      ; minimum (8 hours)
)
OUT
          dns_server_conf.nameservers.each do |name|
            ret << "#{domain}. 3600 IN NS #{name}."
          end
          region.hosts.get_hosts.each do |host|
            next unless host.delegate.dns_server
            next unless dns_server_conf.nameservers.empty?
            plain_adr = region.network.addresses.all.find{|i| i.name! == host.name }
            unless plain_adr
              plain_adr = host.id.first_ipv6
            end

            binding.pry unless plain_adr.name
            ret << "#{domain}. 3600 IN NS #{region.network.fqdn(plain_adr.name)}."
          end

          ret << ""
          ret.join("\n")
        end

        def self.render_conf_block(block_title, block_array)
          notify = block_array||[]
          return "" if notify.empty?
          Util.indent([
            "#{block_title} {",
             Util.indent(notify.join("\n"), 8),
            "};"
          ].join("\n"), 8)+"\n"
        end

        def self.build_config(host)
          return unless host.delegate.dns_server
          forward = {}
          reverse = {}
          host.region.network.addresses.all.each do |address|
            next unless address
            next if address.ips.empty?
            unless address.name!
              Construqt.logger.warn "unreference address #{address.ips.map{|i| i.to_string}}"
              next
            end

            name = host.region.network.fqdn(address.name!)
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
              next unless network
              reverse[network.rev_domains.first] ||= {}
              reverse[network.rev_domains.first][ip.reverse.to_s] ||= "#{ip.reverse} 3600 IN PTR #{name}."
            end
          end

          if host.delegate.dns_server.kind_of?(Hash)
            dns_server_conf_ref = host.delegate.dns_server
          else
            dns_server_conf_ref = {}
          end

          dns_server_conf = OpenStruct.new({
            "serial" => dns_server_conf_ref['serial'],
            "nameservers" => dns_server_conf_ref['nameservers']||[],
            "named_conf_local" => dns_server_conf_ref["named_conf_local"]||"named.conf.local",
            "notify" => dns_server_conf_ref["notify"]||"yes",
            "allow_update" => render_conf_block("allow-update", dns_server_conf_ref["allow_update"]),
            "also_notify" => render_conf_block("also-notify", dns_server_conf_ref["also_notify"])
          })

          include = {}
          forward.each do |domain, lines|
            include[domain] = "/etc/bind/tables/#{domain}.forward"
            host.result.add(self, write_header(dns_server_conf, host.region, domain), Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::DNS), "etc/bind/tables", "#{domain}.forward")
            host.result.add(self, lines.sort.join("\n"), Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::DNS), "etc/bind/tables", "#{domain}.forward")
          end

          reverse.each do |domain, lines|
            include[domain] = "/etc/bind/tables/#{domain}.reverse"
            host.result.add(self, write_header(dns_server_conf, host.region, domain), Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::DNS), "etc/bind/tables", "#{domain}.reverse")
            host.result.add(self, lines.values.sort.join("\n"), Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::DNS), "etc/bind/tables", "#{domain}.reverse")
          end

          include.each do |domain,path|
            host.result.add(self, <<DNS, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::DNS), "etc/bind/#{dns_server_conf.named_conf_local}")
zone "#{domain.to_s}" {
        type master;
        file "#{path}";
        notify #{dns_server_conf.notify};
        allow-query { any; };
#{dns_server_conf.also_notify}
#{dns_server_conf.allow_update}
};
DNS
          end
        end
      end
    end
  end
end
