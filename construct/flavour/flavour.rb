require 'construct/construct.rb'

module Construct
module Flavour

  @flavours = {}

  class FlavourDelegate
    def initialize(flavour)
      @flavour = flavour
    end
    def name
      @flavour.name
    end
    def clazzes
      ret = {
        "opvn" => OpvnDelegate, 
        "gre" => GreDelegate, 
        "host" => HostDelegate, 
        "device"=> DeviceDelegate, 
        "vrrp" => VrrpDelegate, 
        "bridge" => BridgeDelegate,
        "bond" => BondDelegate, 
        "vlan" => VlanDelegate,
        "result" => ResultDelegate,
        "template" => TemplateDelegate
      }
    end
    def pre_clazzes(&block)
      self.clazzes.each do |key, clazz|
        block.call(key, clazz)
      end
    end
#    def clazz(name)
#      delegate = self.clazzes[name]
#      throw "class not found #{name}" unless delegate
#      flavour = @flavour.clazz(name)
#      throw "class not found #{name}" unless flavour
#      delegate.new(flavour)
#    end
    def create_host(name, cfg)
      HostDelegate.new(@flavour.create_host(name, cfg))
    end
#    def create_result(name, cfg)
#      HostDelegate.new(@flavour.create_host(name, cfg))
#    end
    def create_interface(dev_name, cfg)
      clazzes[cfg['clazz']].new(@flavour.create_interface(dev_name, cfg))
    end
    def create_bgp(cfg)
      BgpDelegate.new(@flavour.create_bgp(cfg))
    end
    def create_ipsec(cfg)
      IpsecDelegate.new(@flavour.create_ipsec(cfg))
    end
  end


  def self.add(flavour)
    Construct.logger.info "setup flavour #{flavour.name}"
    @flavours[flavour.name.downcase] = FlavourDelegate.new(flavour)
  end

  @aspects = []
  def self.add_aspect(aspect)
    Construct.logger.info "setup aspect #{aspect.name}"
    @aspects << aspect
  end
  def self.del_aspect(aspect)
    @aspects = @aspects.select{|a| a.name != aspect }
  end
  def self.call_aspects(type, *args)
    @aspects.each { |aspect| aspect.call(type, *args) }
  end

  def self.find(name)
    ret = @flavours[name.downcase]
    throw "flavour #{name} not found" unless ret
    ret
  end

end
end
