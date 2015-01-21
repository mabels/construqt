module Construqt
  module Bgps
    class Bgp
      attr_accessor :lefts, :rights
      attr_reader :use_bfd, :password, :name, :description
      attr_reader :address, :delegate, :tags, :connect_retry
      attr_reader :hold_time, :error_wait_time
      def initialize(cfg)
        @lefts = cfg['lefts']
        @rights = cfg['rights']
        @use_bfd = cfg['use_bfd']
        @password = cfg['password']
        @name = cfg['name']
        @description = cfg['description']
        @address = cfg['address']
        @tags = cfg['tags']
        @delegate = nil
      end

      def build_config()
        (self.rights+self.lefts).each do |iface|
          iface.build_config(nil, nil)
        end
      end

      def ident
        self.lefts.first.ident
      end
    end

    @bgps = {}
    def self.connections
      @bgps.values
    end

    def self.add_connection(cfg)
      throw "my not found #{cfg['my'].inspect}" unless cfg['my']
      throw "as not found #{cfg['as'].inspect}" unless cfg['as']
      throw "as not a as #{cfg['as'].inspect}" unless cfg['as'].kind_of?(As)
      #throw "filter not found #{cfg.inspect}" unless cfg[id]['filter']
      cfg['filter'] ||= {}
      cfg['other'] = nil
      cfg['cfg'] = nil
      cfg['host'] = cfg['my'].host
      cfg['host'].flavour.create_bgp(cfg)
    end



    def self.connection(name, cfg)
      cfg = {}.merge(cfg)
      cfg['left']['mys'] = ((cfg['left']['mys']||[]) + [cfg['left']['my']]).compact
      throw "left need atleast one host" if cfg['left']['mys'].empty?
      cfg['right']['mys'] = ((cfg['right']['mys']||[]) + [cfg['right']['my']]).compact
      throw "right need atleast one host" if cfg['right']['mys'].empty?

      throw "filter not allowed" if cfg['filter']
      throw "duplicated name #{name}" if @bgps[name]
      cfg['lefts'] = []
      cfg['rights'] = []
      cfg['left']['mys'].each do |iface|
        my = cfg['left'].merge('my' => iface)
        my.delete('lefts')
        my.delete('rights')
        cfg['lefts'] << add_connection(my)
      end
      cfg['right']['mys'].each do |iface|
        my = cfg['right'].merge('my' => iface)
        my.delete('lefts')
        my.delete('rights')
        cfg['rights'] << add_connection(my)
      end
      cfg['name'] = name
      cfg.delete('left')
      cfg.delete('right')
      cfg = @bgps[name] = Bgp.new(cfg)
      cfg.lefts.each do |left|
        left.other = cfg.rights.first
        left.cfg = cfg
        left.host.add_bgp(cfg)
      end
      cfg.rights.each do |right|
        right.other = cfg.lefts.first
        right.cfg = cfg
        right.host.add_bgp(cfg)
      end
      cfg
    end

    def self.build_config()
      #binding.pry
      hosts = {}
      @bgps.values.each do |bgp|
        (bgp.rights+bgp.lefts).each do |iface|
          hosts[iface.host.object_id] ||= iface.host
        end
      end
      #binding.pry
      hosts.values.each do |host|
        host.flavour.bgp.header(host) if host.flavour.bgp.respond_to?(:header)
      end
      @bgps.each do |name, bgp|
        bgp.build_config()
      end

      #hosts.values.each do |flavour_bgp|
      #  flavour_bgp.header(flavour_bgp.host)
      #  flavour_bgp.footer(flavour_bgp.host)
      #end
    end

    @filters = {}

    class Filter
      def initialize(name)
        @name = name
        @list = []
      end

      def list
        @list
      end

      def name
        @name
      end

      def addr_v_(cfg)
        [OpenStruct.new({:code=>4, :is? => lambda {|i| i.ipv4? }, :max_prefix=>32}),
         OpenStruct.new({:code=>6, :is? => lambda {|i| i.ipv6? }, :max_prefix=>128})].each do |family|
          addrs = cfg["addr_v#{family.code}"]
          next unless addrs
          cfg.delete("addr_v#{family.code}")
          addr_sub_prefix = cfg['addr_sub_prefix']
          cfg.delete('addr_sub_prefix')
          throw "addrs must be array" unless addrs.kind_of?([].class)
          #puts addr.inspect
          addrs.each do |net|
            next unless family.is?.call(net)
            out = ({ 'network' => Construqt::Addresses::Address.new.add_ip(net.to_string) }).merge(cfg)
            out['prefix_length'] = [net.prefix,family.max_prefix] if addr_sub_prefix
            @list << out
          end
          nil
        end
      end

      def accept(cfg)
        cfg = {}.merge(cfg)
        cfg['rule'] = 'accept'
        addr_v_(cfg)
        throw "we need a network attribute" unless cfg['network']
        @list << cfg if cfg['network']
      end

      def reject(cfg)
        cfg = {}.merge(cfg)
        cfg['rule'] = 'reject'
        addr_v_(cfg)
        throw "we need a network attribute" unless cfg['network']
        @list << cfg if cfg['network']
      end
    end

    class As < OpenStruct
      def initialize(cfg)
        super(cfg)
      end

      def name
        (self.prefix || "AS") + self.as.to_s
      end

      def num
        self.as
      end
    end

    @as = {}
    def self.add_as(as, config)
      throw "as must be a number #{as}" unless as.kind_of?(Fixnum)
      throw "as defined before #{as}" if @as[as]
      config['as'] = as
      @as[as] = As.new(config)
    end

    def self.find_as(as)
      ret = @as[as]
      throw "as not found #{as}" unless ret
      ret
    end

    def self.add_filter(name, &block)
      @filters[name] = Filter.new(name)
      block.call(@filters[name])
      @filters[name]
    end

    def self.filters
      @filters.values
    end

    def self.find_filter(name)
      ret = @filters[name]
      throw "bgp not filter with name #{name}" unless ret
      ret
    end
  end
end
