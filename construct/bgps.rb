module Construct
module Bgps
  class Bgp < OpenStruct
    def initialize(cfg)
      super(cfg)
    end
    def build_config()
      self.left.build_config()  
      self.right.build_config()  
    end
  end
  @bgps = {}
  def self.connections
    @bgps.values
  end
  def self.add_connection(cfg, id)
    throw "my not found #{cfg.inspect}" unless cfg[id]['my']
    throw "host not found #{cfg.inspect}" unless cfg[id]['as']
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
puts ">>>>BGPS>>>>>>>> #{name}"
      bgp.build_config()
      hosts[bgp.left.host.name] = bgp.left
      hosts[bgp.right.host.name] = bgp.right
    end
    hosts.values.each do |flavour_bgp|
      flavour_bgp.once(flavour_bgp.host)
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
