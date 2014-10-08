module Construct
module Bgps
  class Bgp < OpenStruct
    def initialize(cfg)
      super(cfg)
    end
    def build_config()
      self.left.build_config(nil, nil)  
      self.right.build_config(nil, nil)  
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
    cfg
  end
  def self.build_config()
    #binding.pry
    hosts = {}
		@bgps.each do |name, bgp|
			bgp.build_config()
      hosts[bgp.left.host.name] = bgp.left
      hosts[bgp.right.host.name] = bgp.right
    end
    hosts.values.each do |flavour_bgp|
      flavour_bgp.header(flavour_bgp.host)
      flavour_bgp.footer(flavour_bgp.host)
    end
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
    def accept(cfg)
      cfg['rule'] = 'accept'
      @list << cfg
    end
    def reject(cfg)
      cfg['rule'] = 'reject'
      @list << cfg
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
