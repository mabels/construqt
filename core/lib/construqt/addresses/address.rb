module Construqt
  class Addresses

    class Address
      attr_accessor :host
      attr_accessor :interface
      attr_accessor :ips
      attr_accessor :tags

      def ripe(value)
        @ripe = value
        self
      end

      def get_ripe
        @ripe
      end

      def dhcpv4?
        @dhcpv4
      end

      def dhcpv6?
        @dhcpv6
      end

      def loopback?
        @loopback
      end

      def initialize(network)
        @network = network
        self.ips = []
        self.host = nil
        self.interface = nil
        @routes = Routes.new
        self.tags = []
        @loopback = @dhcpv4 = @dhcpv6 = false
        @name = nil
        @service_ip = []
      end

      def inspect
        "@<#{self.class.name}:#{"%x"%object_id} name=#{name!.inspect} "+
        "service_ip=#{@service_ip} ips=#{ips.inspect} host=#{host.inspect} "+
        "interface=#{interface.inspect} routes=#{routes.inspect} "+
        "tags=#{tags.inspect} loopback=#{@loopback}>"
      end

      def cq_ip_address_with_tags(ip, options, routing_table, tags, fqdn)
        _ip = CqIpAddress.new(IPAddress.parse(ip), self, options, routing_table, fqdn)
        Construqt::Tags.join(tags, _ip)
        return _ip
      end

      def resolve_to_cq_ip_address(name, options, routing_table, tags)
        ret = []
        [Construqt::Addresses::IPV4, Construqt::Addresses::IPV6].each do |family|
          Util.cached_resolv(name, family).each do |rdns|
            ret << cq_ip_address_with_tags(rdns.address.to_s, options, routing_table, tags, name)
          end
        end
        ret
      end

      # unless parsed[:first]
      #   binding.pry
      #   throw "add_service_ip needs a addr" unless parsed[:first]
      # end
      # ip = IPAddress.parse(parsed[:first])
      # Construqt::Tags.join(parsed['#']||[], ip)
      # @service_ip << ip
      def add_service_ip(addr, options = {})
        parsed = Construqt::Tags.parse(addr)
        tags = self.tags
        tags << name! if name!
        tags = tags + parsed['#'] if parsed['#'] && !parsed['#'].empty?
        ips = []
        ips << parsed[:first] if parsed[:first]
        (parsed['@'] || []).each do |name|
          @service_ip += resolve_to_cq_ip_address(name, options, nil, tags)
        end
        # binding.pry if parsed['@']
        ips.each do |ip|
          @service_ip << cq_ip_address_with_tags(ip, options, nil, tags, nil)
        end
        self
      end

      def service_ip
        addr = @network.addresses.create()
        found_ipv4 = found_ipv6 = false
        [@service_ip, ips].find do |iparray|
          ipv4 = (iparray.find{|i| i.ipv4? && i.fqdn } ||
                  iparray.find{|i| i.ipv4? } ||
                  first_ipv4)
          ipv6 = (iparray.find{|i| i.ipv6? && i.fqdn } ||
                  iparray.find{|i| i.ipv6? } ||
                  first_ipv6)
          if !found_ipv4 && ipv4
            addr.ips << ipv4
            found_ipv4 = true
          end
          if !found_ipv6 && ipv6
            addr.ips << ipv6
            found_ipv6 = true
          end
        end
        addr.host = self.host
        addr.interface = self.interface
        addr
      end

      def add_addr(addr)
        @ips += addr.ips
        @routes.add_routes(addr.routes)
      end

      def host
        @host || (self.interface && self.interface.host)
      end

      def match_network(ip)
        if ip.ipv4?
          self.v4s.find{|nip| nip.include?(ip) }
        else
          self.v6s.find{|nip| nip.include?(ip) }
        end
      end

      def match_address(ip)
        self.ips.find do |nip|
          nip.ipv4? == ip.ipv4? && (0 == (nip <=> ip))
        end
      end


      def v6s
        self.ips.select{|ip| ip.ipv6? }
      end

      def v4s
        self.ips.select{|ip| ip.ipv4? }
      end

      def by_family(type)
        if type == Construqt::Addresses::IPV4
          v4s
        else
          v6s
        end
      end

      def first_by_family(type)
        if type == Construqt::Addresses::IPV4
          first_ipv4
        else
          first_ipv6
        end
      end

      def first_ipv4
        v4s.first
      end

      def first_ipv6
        v6s.first
      end

      def last_ipv4
        v4s.last
      end

      def last_ipv6
        v6s.last
      end

      def merge_tag(name, &block)
        Construqt::Tags.add(([name]+self.tags).join("#")) { |name| block.call(name) }
      end

      def tags_only(tag)
        ret = Construqt::Tags.parse(tag)
        tags = []
        if ret[:first]
          tags << ret.delete(:first)
        end

        if ret['#']
          tags += ret.delete('#')
        end

        throw "illegal tag for tag method #{tag}" unless ret.empty?
        tags
      end

      def tag(tag)
        self.tags = self.tags + tags_only(tag)
        self
      end

      def set_name(xname)
        (@name, _) = self.merge_tag(xname) { |xname| self }
        self
      end

      def name=(name)
        set_name(name)
      end

      def name
        ret = self.name!
        throw "unreferenced address [#{self.ips.map{|i| i.to_string }}]" unless ret
        ret
      end

      def name!
        return @name if @name
        return "#{self.interface.name}-#{self.interface.host.name}" if self.interface
        return self.host.name if self.host
        nil
      end

      def add_ip(ip, options = {})
        throw "please give a ip #{ip}" if ip.nil?
        parsed = Construqt::Tags.parse(ip)
        throw "only one routing_table per ip allowed" if parsed['!'] and parsed['!'].length > 1
        routing_table = nil
        puts "Routingtable:#{parsed['!']}" if parsed['!']
        routing_table = @network.routing_tables.find(parsed['!'].first) if parsed['!']
        tags = self.tags
        tags << name! if name!
        tags = tags + parsed['#'] if parsed['#'] && !parsed['#'].empty?
        ips = []
        ips << parsed[:first] if parsed[:first]
        (parsed['@'] || []).each do |name|
          self.ips += resolve_to_cq_ip_address(name, options, nil, tags)
        end
        ips.each do |ip|
          if DHCPV4 == ip
            @dhcpv4 = true
          elsif DHCPV6 == ip
            @dhcpv6 = true
          elsif LOOOPBACK == ip
            @loopback = true
          else
            self.ips << cq_ip_address_with_tags(ip, options, routing_table, tags, nil)
          end
        end
        self
      end

      def routes
        @routes
      end

      def add_route_from_tags(dst_tags, src_tags = nil, options = {}, routing_table = nil)
        #if dst_tags.kind_of?(Construqt::RoutingTables::RoutingTableAddRouteFromTags)
        #  dst_tags.attach_address = self
        #  options = dst_tags.options
        #  src_tags = dst_tags.via
        #  routing_table = dst_tags.routing_table
        #  dst_tags = dst_tags.dest
        #binding.pry if dst_tags == "#FANOUT-DE"
        throw "add_route_from_tags need a src_tags" if src_tags.nil?
        throw "add_route_from_tags need a dst_tags" if dst_tags.nil?
        @routes.add TagRoute.new(dst_tags, src_tags, options, self, routing_table)
        self
      end

      def add_route_nearest(dst_tags, options = {}, routing_table = nil)
        #if dst_tags.kind_of?(Construqt::RoutingTables::RoutingTableAddRouteFromTags)
        #  dst_tags.attach_address = self
        #  options = dst_tags.options
        #  src_tags = dst_tags.via
        #  routing_table = dst_tags.routing_table
        #  dst_tags = dst_tags.dest
        throw "add_route_nearest need a dst_tags" if dst_tags.nil?
        @routes.add NearstRoute.new(dst_tags, options, self, routing_table)
        self
      end

      def add_reject_route(addr_or_tag, options = {}, routing_table = nil)
        throw "add_reject_route needs set" if addr_or_tag.nil?
        @routes.add RejectRoute.new(addr_or_tag, options, self, routing_table)
        self
      end

      def add_routes(addr_s, via, options = {})
        addrs = addr_s.kind_of?(Array) ? addr_s : [addr_s]
        addrs.each do |addr|
          if addr.respond_to? :ips
            ips = addr.ips if addr.respond_to? :ips
          else
            ips = [addr]
          end

          ips.each do |i|
            add_route(i.to_string, via, options)
          end
        end

        self
      end

      def build_route(dst, via, options = {})
        if dst == Construqt::Addresses::RAV6
          return RaRoute.new
        end
        #puts "DST => "+dst.class.name+":"+dst.to_s
        via_parsed = Construqt::Tags.parse(via)
        throw "only one routing_table per ip allowed" if via_parsed['!'] and via_parsed['!'].length > 1
        via_s = []
        via_s << via_parsed[:first] if via_parsed[:first]

        routing_table = nil
        routing_table = @network.routing_tables.find(via_parsed['!'].first) if via_parsed['!']
        via_ips = []
        (via_parsed['@'] || []).each do |name|
          via_ips += resolve_to_cq_ip_address(name, options, routing_table, nil)
        end
        via_ips += via_s.map do |ip|
          (unused, ret) = self.merge_tag(([ip]+(via_parsed['#']||[])).join('#')) do |ip|
            if ip == UNREACHABLE
              ip
            else
              CqIpAddress.new(IPAddress.parse(ip), self, options, routing_table, nil)
            end
          end
          ret
        end

        dst_parsed = Construqt::Tags.parse(dst)
        throw "routing_table only allow on via #{dst}" if dst_parsed['!'] and dst_parsed['!'].length > 1
        dst_s = []
        dst_s << dst_parsed[:first] if dst_parsed[:first]
        dst_parsed['#'] ||= []

        dst_ips = []
        (dst_parsed['@'] || []).each do |name|
          dst_ips += resolve_to_cq_ip_address(name, options, routing_table, nil)
        end
        dst_ips += dst_s.map do |ip|
          (unused, ret) = self.merge_tag(([ip]+(dst_parsed['#']||[])).join('#')) do |ip|
            CqIpAddress.new(IPAddress.parse(ip), self, options, routing_table, nil)
          end

          ret
        end

        (via_ips+dst_ips).inject(nil) do |r, ip|
          throw "mixed family are not allowed" if r && r != ip.ipv4?
          r = ip.ipv4?
        end

        Route.new(dst_ips, via_ips, options)
      end

      def add_route(dst, via = nil, option = {})
        @routes.add(build_route(dst, via, option))
        self
      end

      def to_s
        "<Address:Address #{host && host.name}:#{interface && interface.name}:#{@name}=>"+
        "[#{self.ips.map{|i| i.to_string}.join(",")}]>"
      end
    end
  end
end
