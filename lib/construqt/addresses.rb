
module Construqt
  class Addresses

    UNREACHABLE = :unreachable
    LOOOPBACK = :looopback
    DHCPV4 = :dhcpv4
    DHCPV6 = :dhcpv6
    IPV4 = :ipv4
    IPV6 = :ipv6

    def initialize(network)
      @network = network
      @Addresses = []
    end

    def network
      @network
    end

    # hier frieht die hoelle zu!!!
    class CqIpAddress
      attr_reader :ipaddr, :container, :options, :routing_table
      def initialize(ipaddr, container, options, routing_table)
        @ipaddr = ipaddr
        @container = container
        @options = options
        @routing_table = routing_table
      end

      def <=>(oth)
        if oth.kind_of?(CqIpAddress)
          ret = self.ipaddr <=> oth.ipaddr
          #puts "CqIpAddress <=> #{self.ipaddr.to_string} <#{ret}> #{oth.ipaddr}"
        else
          ret = self.ipaddr <=> oth
          #puts "IpAddress <=> #{self.ipaddr.to_string} <#{ret}> #{oth}"
        end

        ret
      end

      def ipv4?
        @ipaddr.ipv4?
      end

      def ipv6?
        @ipaddr.ipv6?
      end

      def include?(a)
        @ipaddr.include?(a)
      end

      def prefix
        @ipaddr.prefix
      end

      def network
        @ipaddr.network
      end

      def to_i
        @ipaddr.to_i
      end

      def to_s
        @ipaddr.to_s
      end

      def to_string
        @ipaddr.to_string
      end

      def to_u32
        @ipaddr.to_u32
      end

      def first
        @ipaddr.first
      end

      def last
        @ipaddr.last
      end

      def broadcast
        @ipaddr.broadcast
      end

      def groups
        @ipaddr.groups
      end

      def compressed
        @ipaddr.compressed
      end

      def reverse
        @ipaddr.reverse
      end

      def address
        @ipaddr.address
      end

      def netmask
        @ipaddr.netmask
      end

      def map(&block)
        @ipaddr.map{|i| block.call(i) }
      end

    end

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

      class Routes
        attr_reader :routes
        def initialize
          @routes = []
        end

        def add_routes(routes)
          @routes += routes.routes
        end

        def add(route)
          throw "route has to be a Route or TagRoute is #{route.class.name}" unless route.kind_of?(Route) or route.kind_of?(TagRoute)
          @routes << route
        end

        class Networks
          def initialize
            @networks = []
          end

          def add(net)
            @networks << net
          end

          def v4s
            IPAddress::summarize(@networks.select{|i| i.ipv4?})
          end

          def v6s
            IPAddress::summarize(@networks.select{|i| i.ipv6?})
          end
        end

        def dst_networks
          ret = Networks.new
          self.each do |rt|
            ret.add(rt.dst)
          end

          ret
        end

        def each(&block)
          each_with_index(&block)
        end

        def each_with_index(&block)
          ret = []
          @routes.each do |route|
            route.resolv.each do |rt|
#puts ">>>>#{route} #{rt}"
              ret << block.call(rt, ret.length)
            end
          end

          ret
        end
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
      end

      def add_addr(addr)
        @ips += addr.ips
        @routes.add_routes(addr.routes)
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
        ips << parsed['@'] if parsed['@']
        ips.each do |ip|
          if DHCPV4 == ip
            @dhcpv4 = true
          elsif DHCPV6 == ip
            @dhcpv6 = true
          elsif LOOOPBACK == ip
            @loopback = true
          else
            _ip = CqIpAddress.new(IPAddress.parse(ip), self, options, routing_table)
            #puts "_ip=#{_ip} #{tags}"
            Construqt::Tags.join(tags, _ip)
            self.ips << _ip
          end
        end

        self
      end

      def routes
        @routes
      end

      #
      #
      class TagRoute
        attr_reader :dst_tag, :via_tag, :options, :routing_table
        def initialize(dst_tag, via_tag, options, address, routing_table)
          @dst_tag = dst_tag
          @via_tag = via_tag
          @options = options
          @address = address
          @routing_table = routing_table
        end

        def resolv
          ret = []
          dst_parse = Construqt::Tags.parse(self.dst_tag)
          throw "routing tag not allowed in dst #{self.dst_tag}" if dst_parse['!']
          via_parse = Construqt::Tags.parse(self.via_tag)
          routing_table = ""
          if via_parse['!']
            if  via_parse['!'].length == 1
              routing_table = '!'+via_parse['!'].first
            else
              throw "only one routing tag allowed #{self.via_tag}"
            end
          end
          #puts ">>>>>>>>>#{self.dst_tag},#{self.via_tag}"
          [OpenStruct.new(:dsts => Construqt::Tags.ips_net(self.dst_tag, Construqt::Addresses::IPV6),
                          :vias => Construqt::Tags.ips_hosts(self.via_tag, Construqt::Addresses::IPV6)),
          OpenStruct.new(:dsts => Construqt::Tags.ips_net(self.dst_tag, Construqt::Addresses::IPV4),
                         :vias => Construqt::Tags.ips_hosts(self.via_tag, Construqt::Addresses::IPV4))].each do |blocks|
            next unless blocks.vias
            next unless blocks.dsts
            next if blocks.dsts.empty?
            puts ">>>>>>>>>#{self.dst_tag} #{blocks.dsts.map{|i| i.to_s}},#{self.via_tag} #{blocks.vias.map{|i| i.to_s}}"
            blocks.vias.each do |via|
              blocks.dsts.each do |dst|
                ret += @address.build_route(dst.to_string, via.to_s+routing_table, options).resolv
              end
            end
          end

          ret
        end
      end

      def add_route_from_tags(dst_tags, src_tags = nil, options = {}, routing_table = nil)
        #if dst_tags.kind_of?(Construqt::RoutingTables::RoutingTableAddRouteFromTags)
        #  dst_tags.attach_address = self
        #  options = dst_tags.options
        #  src_tags = dst_tags.via
        #  routing_table = dst_tags.routing_table
        #  dst_tags = dst_tags.dest
        throw "add_route_from_tags need a src_tags" if src_tags.nil?
        throw "add_route_from_tags need a dst_tags" if dst_tags.nil?
        @routes.add TagRoute.new(dst_tags, src_tags, options, self, routing_table)
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

      class Route
        def initialize(dst_ips, via_ips, options)
          @dst_ips = dst_ips
          @via_ips = via_ips
          @options = options
        end

        class DirectRoute
          attr_reader :dst, :via, :type, :metric, :options
          def initialize(dst, via, type, metric, options)
            @dst = dst
            @via = via
            @type = type
            @metric = metric
            @options = options
          end
        end

        def resolv
          ret = []
          @via_ips.each do |via|
            if via == UNREACHABLE
              via = nil
              type = 'unreachable'
            else
              type = nil
            end

            @dst_ips.each do |dst|
              ret << DirectRoute.new(dst, via, type, @options['metric'], @options)
            end
          end

          ret
        end
      end

      def build_route(dst, via, options = {})
        #puts "DST => "+dst.class.name+":"+dst.to_s
        via_parsed = Construqt::Tags.parse(via)
        throw "only one routing_table per ip allowed" if via_parsed['!'] and via_parsed['!'].length > 1
        via_s = []
        via_s << via_parsed[:first] if via_parsed[:first]
        via_s << via_parsed['@'] if via_parsed['@']
        routing_table = nil
        routing_table = @network.routing_tables.find(via_parsed['!'].first) if via_parsed['!']
        via_ips = via_s.map do |ip|
          (unused, ret) = self.merge_tag(([ip]+(via_parsed['#']||[])).join('#')) do |ip|
            if ip == UNREACHABLE
              ip
            else
              CqIpAddress.new(IPAddress.parse(ip), self, options, routing_table)
            end
          end

          ret
        end

        dst_parsed = Construqt::Tags.parse(dst)
        throw "routing_table only allow on via #{dst}" if dst_parsed['!'] and dst_parsed['!'].length > 1
        dst_s = []
        dst_s << dst_parsed[:first] if dst_parsed[:first]
        dst_s << dst_parsed['@'] if dst_parsed['@']
        dst_parsed['#'] ||= []
        dst_ips = dst_s.map do |ip|
          (unused, ret) = self.merge_tag(([ip]+(dst_parsed['#']||[])).join('#')) do |ip|
            CqIpAddress.new(IPAddress.parse(ip), self, options, routing_table)
          end

          ret
        end

        (via_ips+dst_ips).inject(nil) do |r, ip|
          throw "mixed family are not allowed" if r && r != ip.ipv4?
          r = ip.ipv4?
        end

        Route.new(dst_ips, via_ips, options)
      end

      def add_route(dst, via, option = {})
        @routes.add(build_route(dst, via, option))
        self
      end

      def to_s
        "<Address:Address #{@name}=>[#{self.ips.map{|i| i.to_string}.join(",")}]>"
      end
    end

    def create
      ret = Address.new(@network)
      @Addresses << ret
      ret
    end

    def tag(tag)
      create.tag(tag)
    end

    def add_ip(ip, region = "")
      create.add_ip(ip, region)
    end

    def add_route(dest, via = nil)
      create.add_route(dest, via)
    end

    def set_name(name)
      create.set_name(name)
    end

    def all
      @Addresses
    end

    def v4_default_route(tag = "")
      nets = [(1..9),(11..126),(128..168),(170..171),(173..191),(193..223)].map do |range|
        range.to_a.map{|i| "#{i}.0.0.0/8"}
      end.flatten
      nets += (0..255).to_a.select{|i| i!=254}.map{|i| "169.#{i}.0.0/16" }
      nets += (0..255).to_a.select{|i| !(16<=i&&i<31)}.map{|i| "172.#{i}.0.0/16" }
      nets += (0..255).to_a.select{|i| i!=168}.map{|i| "192.#{i}.0.0/16" }

      v4_default_route = self.create
      v4_default_route.set_name(tag).tag(tag) if tag && !tag.empty?
      IPAddress::IPv4::summarize(*(nets.map{|i| IPAddress::IPv4.new(i) })).each do |i|
        v4_default_route.add_ip(i.to_string)
      end

      v4_default_route
    end
  end
end
