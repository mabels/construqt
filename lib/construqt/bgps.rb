module Construqt
  module Bgps
    class Bgp < OpenStruct
      def initialize(cfg)
        super(cfg)
      end

      def build_config()
        self.left.build_config(nil, nil)
        self.right.build_config(nil, nil)
      end

      def ident
        self.left.ident
      end
    end

    @bgps = {}
    def self.connections
      @bgps.values
    end

    def self.add_connection(cfg, id)
      throw "my not found #{cfg[id]['my'].inspect}" unless cfg[id]['my']
      throw "as not found #{cfg[id]['as'].inspect}" unless cfg[id]['as']
      throw "as not a as #{cfg[id]['as'].inspect}" unless cfg[id]['as'].kind_of?(As)
      #throw "filter not found #{cfg.inspect}" unless cfg[id]['filter']
      cfg[id]['filter'] ||= {}
      cfg[id]['other'] = nil
      cfg[id]['cfg'] = nil
      cfg[id]['host'] = cfg[id]['my'].host
      cfg[id] = cfg[id]['host'].flavour.create_bgp(cfg[id])
    end

    def self.connection(name, cfg)
      throw "filter not allowed" if cfg['filter']
      throw "duplicated name #{name}" if @bgps[name]
      add_connection(cfg, 'left')
      add_connection(cfg, 'right')
      cfg['name'] = name

      cfg = @bgps[name] = Bgp.new(cfg)
      cfg.left.other = cfg.right
      cfg.left.cfg = cfg
      cfg.right.other = cfg.left
      cfg.right.cfg = cfg

      cfg.right.host.add_bgp(cfg)
      cfg.left.host.add_bgp(cfg)
      cfg
    end

    def self.build_config()
      #binding.pry
      hosts = {}
      @bgps.values.each do |bgp|
        hosts[bgp.left.host.object_id] ||= bgp.left.host
        hosts[bgp.right.host.object_id] ||= bgp.right.host
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
        @list << cfg if cfg['network']
      end

      def reject(cfg)
        cfg = {}.merge(cfg)
        cfg['rule'] = 'reject'
        addr_v_(cfg)
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
