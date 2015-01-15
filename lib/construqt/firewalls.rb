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

#      def interface
#        @interface = true
#        self
#      end
#
#      def get_interface
#        @interface
#      end
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
        elsif defined?(val)
          addr = FromTo.resolver(val, Construqt::Addresses::IPV4).first
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

      def include_routes
        @include_routes = true
        self
      end

      def include_routes?
        @include_routes
      end

      def from_me
        @from_me = true
        self
      end

      def from_me?
        @from_me
      end

      def to_me
        @to_me = true
        self
      end

      def to_me?
        @to_me
      end

      def from_my_net
        @from_my_net = true
        self
      end

      def from_my_net?
        @from_my_net
      end

      def to_my_net
        @to_my_net = true
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

      def self.to_host_addrs(addrs)
        addrs.map do |i|
          if i.to_i == 0 ||
             (i.ipv4? && i.prefix != 32 && i.network == i) ||
             (i.ipv6? && i.prefix != 128 && i.network == i)
            # default or i is a network
            nil
          else
            IPAddress.parse(i.to_s)
          end
        end.compact
      end

      def self.resolver(str, family)
        return [] if str.nil? || str.strip.empty?
        # first char is not a # or @ add first char #
        str_a = str.strip.gsub(/\s/, '').split('')
        if str_a[0] != "#" or str_a[0] != '@'
          str_a.unshift('#')
        end

        types = {}
        wait_hash_or_at = true
        fill = nil
        while (current = str_a.shift)
          if current == '#' or current == '@'
            types[current] ||= []
            fill = []
            types[current] << fill
          else
            fill << current
          end
        end

        ret = []
        Resolv::DNS.open do |dns|
          types.each do |type, types|
            types = types.map{|i| i.join('') }.sort.uniq
            if type == '#'
              ret += Construqt::Tags.ips_adr(types.join('#'), family)
            elsif type == '@'
              types.each do |name|
                begin
                  tmp = IPAddress.parse(name)
                  if (tmp.ipv4? && family == Construqt::Addresses::IPV4) || (tmp.ipv6? && family == Construqt::Addresses::IPV6)
                    ret += [tmp]
                  end
                rescue Exception => e
                  ress = dns.getresources name, family == Construqt::Addresses::IPV6 ? Resolv::DNS::Resource::IN::AAAA : Resolv::DNS::Resource::IN::A
                  throw "can not resolv #{name}" if ress.empty?
                  ret += ress.map{|i| IPAddress.parse(i.address.to_s) }
                end
              end
            end
          end
        end
        ret
      end


      def from_list(family)
        FromTo._list(family, self.attached_interface, self.get_from_host, self.get_from_net, self.from_me?, self.include_routes?, self.from_my_net?)
      end

      def to_list(family)
        FromTo._list(family, self.attached_interface, self.get_to_host, self.get_to_net, self.to_me?, self.include_routes?, self.to_my_net?)
      end

      def self.to_ipaddrs(addrs)
        addrs.map{|i| i.ipaddr}
      end

      def self._list(family, iface, _host, _net, _me, _route, _my_net)
        family_list_method = family==Construqt::Addresses::IPV6 ? :v6s : :v4s
        _list = []
        if _me # if my interface
          _list << to_host_addrs(to_ipaddrs(iface.address.send(family_list_method)))
          if _route
            _list << iface.address.routes.dst_networks.send(family_list_method)
          end
        end

        if _my_net #if my interface net
          _list << to_ipaddrs(iface.address.send(family_list_method))
          if _route
            _list << iface.address.routes.dst_networks.send(family_list_method)
          end
        end

        unless _host == :undefined #to this host
          if _host == :to_host
            _list << to_host_addrs(to_ipaddrs(iface.host.address.send(family_list_method)))
            if _route
              _list << iface.host.address.routes.dst_networks.send(family_list_method)
            end
          else
            _list << to_host_addrs(resolver(_host, family))
          end
        end

        unless _net == :undefined #to this host network
          if _net == :to_net
            _list << to_ipaddrs(iface.host.address.send(family_list_method))
            if _route
              _list << iface.host.address.routes.dst_networks.send(family_list_method)
            end
          else
            _list << resolver(_net, family)
          end
        end

        IPAddress.summarize(_list.flatten.compact)
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
          include FromTo
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

    def self.add(name, &block)
      throw "firewall with this name exists #{name}" if @firewalls[name]
      fw = @firewalls[name] = Firewall.new(name)
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
