require 'resolv'
module Construqt
  module Firewalls

    @firewalls = {}
    module Actions
      NOTRACK = :NOTRACK
      SNAT = :SNAT
      DNAT = :DNAT
      ACCEPT = :ACCEPT
      DROP = :DROP
      TCPMSS = :TCPMSS
    end

    module ICMP
      Ping = :ping
    end

    module Ipv4Ipv6
      def ipv6
        @family = Construqt::Addresses::IPV6
        self
      end

      def ipv6?
        if !defined?(@family)
          true
        else
          @family == Construqt::Addresses::IPV6
        end
      end

      def ipv4
        @family = Construqt::Addresses::IPV4
        self
      end

      def ipv4?
        if !defined?(@family)
          true
        else
          @family == Construqt::Addresses::IPV4
        end
      end
    end

    module TcpMss
      def mss(mss)
        ipv4_mss(mss)
        ipv6_mss(mss-((2*(128-32))/8))
        self
      end
      def ipv6_mss(mss)
        @ipv6_mss = mss
        self
      end
      def get_ipv6_mss
        @ipv6_mss
      end
      def ipv4_mss(mss)
        @ipv4_mss = mss
        self
      end
      def get_ipv4_mss
        @ipv4_mss
      end
    end

    module AttachInterface
      attr_reader :attached_interface
      def _rules_attach_iface(iface)
        @attached_interface = iface
        @rules = @rules.map do |entry|
          ret = entry.clone
          ret.attached_interface = iface
          ret
        end

        self
      end

      def attach_iface(iface)
        ret = self.clone
        ret._rules_attach_iface(iface)
      end
    end

    module Protocols
      include Util::Chainable
      chainable_attr :tcp
      chainable_attr :udp
      chainable_attr :esp
      chainable_attr :ah
      chainable_attr :icmp
      chainable_attr :type, nil

      def proto_flags(proto, flags)
        @proto_flags ||= {}
        @proto_flags[proto] = flags
        self
      end

      def get_proto_flags
        @proto_flags ||= {}
      end

      def ipv6
        @family = Construqt::Addresses::IPV6
        self
      end

      def ipv6?
        if !defined?(@family)
          block.ipv6?
        else
          @family == Construqt::Addresses::IPV6
        end
      end

      def ipv4
        @family = Construqt::Addresses::IPV4
        self
      end

      def ipv4?
        if !defined?(@family)
          block.ipv4?
        else
          @family == Construqt::Addresses::IPV4
        end
      end

      def get_protocols(family)
        protocols = {
          'tcp' => self.tcp?,
          'udp' => self.udp?,
          'esp' => self.esp?,
          'ah' => self.ah?
        }
        protocols[family == Construqt::Addresses::IPV6 ? 'icmpv6' : 'icmp'] = self.icmp?
        ret = protocols.keys.select{ |i| protocols[i] }
        #puts ">>>>>>#{protocols.inspect}=>#{ret.inspect}"
        ret
      end
    end

    module ActionAndInterface
      def action(val)
        @action = val
        self
      end

      def get_action
        @action
      end
    end

    module Log
      def log(val)
        @log = val
        self
      end

      def get_log
        @log
      end
    end

    module ToDestFromSource
      # NAT only ipv4
      def to_source(val=:my_first)
        @to_source = val
        self
      end

      def _to_dest_to_source(val)
        addr = nil
        if val == :my_first
          addr = self.attached_interface.address.v4s.first
        elsif defined?(val) && val && !val.strip.empty?
          addr = FromTo.resolver(val, Construqt::Addresses::IPV4).first.ip_addr
        end
        addr ?  [addr] : []
      end

      def get_to_source
        _to_dest_to_source(@to_source)
      end

      def to_dest(val=:my_first)
        @to_dest = val
        self
      end

      def get_to_dest
        _to_dest_to_source(@to_dest)
      end
    end

    module FromIsInOutBound
      def from_is_outside?
        @from_is == :outside
      end

      def from_is_inside?
        @from_is == :inside
      end

      def from_is_inside
        @from_is = :inside
        self
      end

      def from_is_outside
        @from_is = :outside
        self
      end
    end

    module Ports
      def sport(port)
        @sports ||= []
        @sports << port
        self
      end

      def get_sports
        @sports ||= []
      end

      def dport(port)
        @dports ||= []
        @dports << port
        self
      end

      def get_dports
        @dports ||= []
      end
    end

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
        if addr.to_i == 0 ||
            (addr.ipv4? && addr.prefix != 32 && addr.network == addr) ||
            (addr.ipv6? && addr.prefix != 128 && addr.network == addr)
          # default or i is a network
          nil
        else
          IPAddress.parse(addr.to_s)
        end
      end

      def self.to_host_addrs(addrs)
        addrs.map { |addr| to_host_addr(addr) }.compact
      end

      class FwToken
        attr_reader :type, :str
        def initialize(type, str = "")
          @type = type
          @str = str
        end
        def is_tag?
          @type == '#'
        end
        def is_literal?
          @type == '@'
        end
      end

      class FwIpAddress
        def merge(ip)
          FwIpAddress.new
            .set_ip_addr(ip_addr)
            .missing(@fwtoken, @family, @missing)
        end

        def missing(fwtoken, family, missing = true)
          @fwtoken = fwtoken
          @family = family
          @missing = missing
          self
        end

        def missing?
          @missing
        end

        def self.missing(fwtoken, family)
          FwIpAddress.new.missing(fwtoken, family)
        end

        def to_string
          missing? ? "[MISSING:#{@family}]" : ip_addr.to_string
        end

        def to_s
          "#<#{self.class.name}:#{self.object_id}:#{ip_addr.to_string}>"
        end

        def ip_addr
          @ip_addr
        end
        def set_ip_addr(ip)
          @ip_addr = ip
          self
        end

        def self.create(fwtoken, ips, ret)
          ips.each do |ip|
            if ip.kind_of?(FwIpAddress)
              ret << ip
            elsif ip.kind_of?(IPAddress) || ip.kind_of?(Addresses::CqIpAddress)
              ret << FwIpAddress.new.set_ip_addr(ip)
            else
              throw "unknown type #{ip.class.name}"
            end
          end

          ret
        end
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

      class FwIpAddresses
        def initialize
          @list = []
        end

        def empty?
          @list.empty?
        end

        def missing?
          !!@list.find{|i| i.missing?}
        end


        def size
          @list.length
        end

        def set_list(list)
          @list = list
          self
        end

        def merge!(&block)
          @list = @list.map do |ip|
            block.call(ip).map { |i| ip.merge(i) }
          end.flatten
          @cached_list = false
        end

        def map(&block)
          _list.map{|i| block.call(i) }
        end

        def each_without_missing(&block)
          _list.each{|i| !i.missing? && block.call(i) }
        end

        def size_without_missing
          _list.select{|i| !i.missing?}.size
        end

        def first
          _list.find{|i| !i.missing?}
        end

#        class FwIpAddressList
#          def initialize(list)
#            @list = list
#          end
#          def empty?
#            @list.empty?
#          end
#
#          def size
#            @list.size
#          end
#          def size_without_missing
#            @list.select{|fwaddr| !fwaddr.missing? }.size
#          end
#          def map(&block)
#            @list.map{|i| block.call(i) }
#          end
#        end

        def _list
          # this is slow i cache now the result
          if @cached_list && @cached_list.size == @list.size
            return @cached_list.list
          end
          missing = @list.select{|fwaddr| fwaddr.missing? }[0..0]
          list = @list.select{|fwaddr| !fwaddr.missing? }.map{|i| i.ip_addr}
          #puts ">>>#{missing} #{list}"
          ret = IPAddress.summarize(list).map{|i| FwIpAddress.new.set_ip_addr(i) }+missing
          @cached_list = OpenStruct.new(:list => ret, :size => @list.size)
          ret
        end

        def add_missing(token, family)
          @list << FwIpAddress.missing(FwToken.new(token), family)
        end

        def add_ip_addrs(ip_addrs)
          ip_addrs.each do |ipaddr|
            throw "ipaddr have to be ipaddress but is #{ipaddr.class.name} #{ipaddr}" unless ipaddr.kind_of?(IPAddress)
            @list << FwIpAddress.new.set_ip_addr(ipaddr)
          end
        end

        def add_fwipaddresses(fw_addrs)
          fw_addrs.each do |fwaddr|
            throw "fwaddr have to be fwipaddress but is #{fwaddr.class.name}" unless fwaddr.kind_of?(FwIpAddress)
            @list << fwaddr
          end
        end
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
          binding.pry if iface.host.name == "rt-mam-wl-de"
          _list.merge! do |fwip|
            found = []
            iface.host.address.ips.each do |ifip|
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

    module InputOutputOnly
      # the big side effect

      def request_only?
        (!@set && true) || @request_only
      end

      def respond_only?
        (!@set && true) || @respond_only
      end

      def request_only
        @set = true
        @request_only = true
        @respond_only = false
        self
      end

      def respond_only
        @set = true
        @request_only = false
        @respond_only = true
        self
      end

      def prerouting
        @output = false
        @prerouting = true
        request_only
        self
      end

      def prerouting?
        @prerouting
      end

      def output
        @output = true
        @prerouting = false
        respond_only
        self
      end

      def output?
        @output
      end

      def postrouting
        @input = false
        @postrouting = true
        request_only
        self
      end

      def postrouting?
        @postrouting
      end
    end

    class AttachedFirewall
      def initialize(iface, firewall)
        @iface = iface
        @firewall = firewall
      end

      def get_raw
        @firewall.get_raw(@iface)
      end

      def get_nat
        @firewall.get_nat(@iface)
      end

      def get_forward
        @firewall.get_forward(@iface)
      end

      def get_host
        @firewall.get_host(@iface)
      end

      def ipv4?
        @firewall.ipv4?
      end

      def ipv6?
        @firewall.ipv6?
      end
    end

    class Firewall
      def initialize(name)
        @name = name
        @raw = Raw.new(self)
        @nat = Nat.new(self)
        @forward = Forward.new(self)
        @host = Host.new(self)
        @ipv4 = true
        @ipv6 = true
      end

      def attach_iface(iface)
        AttachedFirewall.new(iface, self)
      end

      def ipv4?
        @ipv4
      end

      def only_ipv4
        @ipv4 = true
        @ipv6 = false
        self.clone
      end

      def ipv6?
        @ipv6
      end

      def only_ipv6
        @ipv4 = false
        @ipv6 = true
        self.clone
      end

      def name
        @name
      end

      class Raw
        include Ipv4Ipv6
        include AttachInterface
        attr_reader :firewall
        attr_accessor :interface
        def initialize(firewall)
          @firewall = firewall
          @rules = []
        end

        class RawEntry
          attr_accessor :attached_interface
          include Protocols
          include ActionAndInterface
          include Ports
          include FromTo
          include Log
          include InputOutputOnly
          include FromIsInOutBound

          attr_reader :block
          def initialize(block)
            @block = block
          end
        end

        def entry!
          ret = RawEntry.new(self)
          ret.attached_interface = self.attached_interface
          ret
        end

        def add
          entry = self.entry!
          @rules << entry
          entry
        end

        def rules
          @rules
        end
      end

      def get_raw(iface)
        @raw.attach_iface(iface)
      end

      def raw(&block)
        block.call(@raw)
      end

      class Nat
        include Ipv4Ipv6
        include AttachInterface
        attr_reader :firewall, :rules
        attr_accessor :interface
        def initialize(firewall)
          @firewall = firewall
          @rules = []
        end

        class NatEntry
          attr_accessor :attached_interface
          include FromTo
          include InputOutputOnly
          include Ports
          include Protocols
          include ToDestFromSource
          include ActionAndInterface
          include FromIsInOutBound

          def connection?
            false
          end

          def get_log
            nil
          end

          def link_local?
            false
          end

          attr_reader :block
          def initialize(block)
            @block = block
          end
        end

        def entry!
          ret = NatEntry.new(self)
          ret.attached_interface = self.attached_interface
          ret
        end

        def add
          entry = self.entry!
          @rules << entry
          entry
        end
      end

      def get_nat(iface)
        @nat.attach_iface(iface)
      end

      def nat(&block)
        block.call(@nat)
      end

      class Mangle
        @rules = []
        class Tcpmss
        end

        def tcpmss
          @rules << Tcpmss.new
        end
      end

      def mangle(&block)
        block.call(@mangle)
      end

      class Forward
        include AttachInterface
        include Ipv4Ipv6
        attr_reader :firewall, :rules
        attr_accessor :interface
        def initialize(firewall)
          @firewall = firewall
          @rules = []
        end

        class ForwardEntry
          attr_accessor :attached_interface
          include Util::Chainable
          include FromTo
          include InputOutputOnly
          include TcpMss
          include Ports
          include ActionAndInterface
          include FromIsInOutBound
          include Log
          include Protocols

          chainable_attr :connection
          chainable_attr :link_local

          def link_local(link_local = true)
            @link_local = link_local
            self
          end

          def link_local?
            @link_local
          end

          attr_reader :block
          def initialize(block)
            @block = block
          end
        end

        def entry!
          ret = ForwardEntry.new(self)
          ret.attached_interface = self.attached_interface
          ret
        end

        def add
          entry = self.entry!
          #puts "ForwardEntry: #{@firewall.name} #{entry.request_only?} #{entry.output_only?}"
          @rules << entry
          entry
        end
      end

      def get_forward(iface)
        @forward.attach_iface(iface)
      end

      def forward(&block)
        block.call(@forward)
      end

      class Host
        include Ipv4Ipv6
        include AttachInterface
        attr_reader :firewall, :rules
        attr_accessor :interface
        def initialize(firewall)
          @firewall = firewall
          @rules = []
        end

        class HostEntry < Forward::ForwardEntry
          #include Util::Chainable
          #alias_method :from_me, :from_my_net
          #alias_method :to_me, :to_my_net
        end

        def entry!
          ret = HostEntry.new(self)
          ret.attached_interface = self.attached_interface
          ret
        end

        def add
          entry = self.entry!
          #puts "ForwardEntry: #{@firewall.name} #{entry.request_only?} #{entry.respond_only?}"
          @rules << entry
          entry
        end
      end

      def get_host(iface)
        @host.attach_iface(iface)
      end

      def host(&block)
        block.call(@host)
      end

      #    class Input
      #      class All
      #      end

      #      @rules = []
      #      def all(cfg)
      #        @rules << All.new(cfg)
      #      end

      #    end
    end

    def self.add(name = nil, &block)
      if name == nil
        fw = Firewall.new(name)
      else
        throw "firewall with this name exists #{name}" if @firewalls[name]
        fw = @firewalls[name] = Firewall.new(name)
      end

      block.call(fw)
      fw
    end

    def self.find(name)
      ret = @firewalls[name]
      throw "firewall with this name #{name} not found" unless @firewalls[name]
      ret
    end
  end
end
