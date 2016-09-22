module Construqt
  module Firewalls
    module FromTo
      def copy_from_to(rule)
        from_filter_local(rule.from_filter_local?)
        from_net(rule.get_from_net)
        from_host(rule.get_from_host)
        not_from(rule.not_from?)
        from_me(rule.from_me?)
        from_my_net(rule.from_my_net?)
        to_filter_local(rule.to_filter_local?)
        to_net(rule.get_to_net)
        to_host(rule.get_to_host)
        not_to(rule.not_to?)
        to_me(rule.to_me?)
        to_my_net(rule.to_my_net?)
        include_routes(rule.include_routes?)
      end

      def from_filter_local(val = true)
        @from_filter_local = val
        self
      end

      def from_filter_local?
        defined?(@from_filter_local) ? @from_filter_local : false
      end

      def to_filter_local(val = true)
        @to_filter_local = val
        self
      end

      def to_filter_local?
        defined?(@to_filter_local) ? @to_filter_local : false
      end

      def from_net(val = :to_net)
        @from_net = val
        self
      end

      def get_from_net()
        defined?(@from_net) ? @from_net : :undefined
      end

      def to_net(val = :to_net)
        @to_net = val
        self
      end

      def get_to_net()
        defined?(@to_net) ? @to_net : :undefined
        @to_net
      end

      def not_from(val = true)
        @not_from=val
        self
      end

      def not_from?
        @not_from
      end

      def not_to(val = true)
        @not_to=val
        self
      end

      def not_to?
        @not_to
      end

      def from_host(val = :to_host)
        @from_host = val
        self
      end

      def get_from_host()
        defined?(@from_host) ? @from_host : :undefined
      end

      def to_host(val = :to_host)
        @to_host = val
        self
      end

      def get_to_host
        defined?(@to_host) ? @to_host : :undefined
      end

      def include_routes(val = true)
        @include_routes = val
        self
      end

      def include_routes?
        @include_routes
      end

      def from_me(val = true)
        @from_me = val
        self
      end

      def from_me?
        @from_me
      end

      def to_me(val = true)
        @to_me = val
        self
      end

      def to_me?
        @to_me
      end

      def from_my_net(val = true)
        @from_my_net = val
        self
      end

      def from_my_net?
        @from_my_net
      end

      def to_my_net(val = true)
        @to_my_net = val
        self
      end

      def to_my_net?
        @to_my_net
      end

      def self.filter_routes(routes, family)
        routes.map{|i| i.dst }.select{|i| family == Construqt::Addresses::IPV6 ? i.ipv6? : i.ipv4? }
      end

      def self.try_tags_as_ipaddress(family, net, host)
        list = []
        if host
          list = Construqt::Tags.ips_hosts(host, family)
        end

        list += Construqt::Tags.ips_net(net, family)
        IPAddress.summarize(list.map{|i| i.to_i == 0 ? nil : IPAddress.parse(i.to_string) }.compact)
      end

      def self.to_host_addr(addr)
        if addr.is_unspecified() ||
            (addr.ipv4? && addr.prefix.num != 32 && addr.network == addr) ||
            (addr.ipv6? && addr.prefix.num != 128 && addr.network == addr)
          # default or i is a network
          nil
        else
          IPAddress.parse(addr.to_s)
        end
      end

      def self.to_host_addrs(addrs)
        addrs.map { |addr| to_host_addr(addr) }.compact
      end

      DNS_CACHE={}
      def self.cached_resolv(dns, name, family)
        DNS_CACHE[family] ||={}
        ret = DNS_CACHE[family][name]
        return ret if ret
        #puts ">>resolv:extern:#{name}:#{family}"
        DNS_CACHE[family][name] = dns.getresources(name, family)
      end

      def self.resolver(str, family)
        return [] if str.nil? || str.strip.empty?
        # first char is not a # or @ add first char #
        parsed = Construqt::Tags::parse(str)
        fwtokens = []
        fwtokens = fwtokens + (parsed['@']||[]).map{|i| FwToken.new('@', i) }
        fwtokens = fwtokens + (parsed['#']||[]).map{|i| FwToken.new('#', i) }
        fwtokens << FwToken.new('#', parsed[:first]) if parsed[:first]
        #puts "#{str} #{parsed.inspect} => #{fwtokens.inspect}"
        ret = []
        dns = Resolv::DNS.open
        fwtokens.each do |fwtoken|
          if fwtoken.is_tag?
            ips = Construqt::Tags.ips_adr(fwtoken.str, family)
            #puts ">>>>>#{fwtoken.inspect} #{ips}"
            if ips.empty?
              FwIpAddress.create(fwtoken, [FwIpAddress.missing(fwtoken, family)], ret)
            else
              FwIpAddress.create(fwtoken, ips, ret)
            end

          elsif fwtoken.is_literal?
            begin
              tmp = IPAddress.parse(fwtoken.str)
              if (tmp.ipv4? && family == Construqt::Addresses::IPV4) || (tmp.ipv6? && family == Construqt::Addresses::IPV6)
                FwIpAddress.create(fwtoken, [FwIpAddress.new.set_ip_addr(tmp)], ret)
              else
                FwIpAddress.create(fwtoken, [FwIpAddress.missing(fwtoken, family)], ret)
              end

            rescue Exception => e
              ress = cached_resolv(dns, fwtoken.str, family == Construqt::Addresses::IPV6 ? Resolv::DNS::Resource::IN::AAAA : Resolv::DNS::Resource::IN::A)
              unless ress.empty?
                FwIpAddress.create([fwtoken], ress.map{|i| IPAddress.parse(i.address.to_s) }, ret)
              else
                FwIpAddress.create([fwtoken], [FwIpAddress.missing(fwtoken, family)], ret)
              end
            end
          else
            throw "unknown type #{fwtoken.type}"
          end
        end

        #puts ">>>>><<<<<<<<<<#{fwtokens}"

        ret
      end

      def from_list(family)
        FromTo._list(family, self.attached_interface, self.get_from_host, self.get_from_net,
                     self.from_me?, self.include_routes?, self.from_my_net?,
                     self.from_filter_local?)
      end

      def to_list(family)
        FromTo._list(family, self.attached_interface, self.get_to_host, self.get_to_net,
                     self.to_me?, self.include_routes?, self.to_my_net?,
                     self.to_filter_local?)
      end

      def self.to_ipaddrs(addrs)
        addrs.map{|i| i.ipaddr}
      end

      def self._list(family, iface, _host, _net, _me, _route, _my_net, _filter_local)
        family_list_method = family==Construqt::Addresses::IPV6 ? :v6s : :v4s
        _list = FwIpAddresses.new
        iface_address_nil = false
        if _me # if my interface
          if iface.address
            tmp = to_host_addrs(to_ipaddrs(iface.address.send(family_list_method)))
            if _route
              tmp += iface.address.routes.dst_networks.send(family_list_method)
            end
          else
            tmp = []
          end

          tmp.empty? ? _list.add_missing("_me", family) : _list.add_ip_addrs(tmp)
        end

        if _my_net #if my interface net
          if iface.address
            tmp = to_ipaddrs(iface.address.send(family_list_method))
            if _route
              tmp += iface.address.routes.dst_networks.send(family_list_method)
            end
          else
            tmp = []
          end

          tmp.empty? ? _list.add_missing("_my_net", family) : _list.add_ip_addrs(tmp)
        end

        unless _host == :undefined #to this host
          if _host == :to_host
            tmp = to_host_addrs(to_ipaddrs(iface.host.address.send(family_list_method)))
            if _route
              tmp += iface.host.address.routes.dst_networks.send(family_list_method)
            end

            tmp.empty? ? _list.add_missing("_host", family) : _list.add_ip_addrs(tmp)
          else
            #            puts "DDDDDDDDDDDDD#{_host}"
            _list.add_fwipaddresses(resolver(_host, family).select do |fw|
              if fw.ip_addr
                (ret = to_host_addr(fw.ip_addr)) ?  fw.set_ip_addr(ret) : false
              else
                fw
              end
            end)
          end
        end

        unless _net == :undefined #to this host network
          if _net == :to_net
            tmp = to_ipaddrs(iface.host.address.send(family_list_method))
            if _route
              tmp += iface.host.address.routes.dst_networks.send(family_list_method)
            end

            tmp.empty? ? _list.add_missing("_net", family) : _list.add_ip_addrs(tmp)
          else
            _list.add_fwipaddresses(resolver(_net, family))
          end
        end

        if _filter_local
          #binding.pry if iface.host.name == "rt-mam-wl-de"
          _list.merge! do |fwip|
            found = []
            iface.host.address.ips.each do |ifip|
              #binding.pry if ifip.nil? or fwip.ip_addr.nil?
              next if fwip.ip_addr.nil?
              next unless ifip.ipv4? == fwip.ip_addr.ipv4?
              fwip.ip_addr.include?(ifip) and
                (found << (ifip.prefix.to_i < fwip.ip_addr.prefix.to_i ? ifip : fwip.ip_addr))
            end

            found
          end
        end

        _list
      end
    end
  end
end
