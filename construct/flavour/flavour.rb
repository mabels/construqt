require 'construct/flavour/delegates.rb'
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
        "opvn" => OvpnDelegate, 
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
    def clazz(name)
      delegate = self.clazzes[name]
      throw "class not found #{name}" unless delegate
      flavour = @flavour.clazz(name)
      throw "class not found #{name}" unless flavour
      delegate.new(flavour)
    end
    def create_interface(dev_name, cfg)
      InterfaceDelegate.new(@flavour.create_interface(dev_name, cfg))
    end
    def create_bgp(cfg)
      BgpDelegate.new(@flavour.create_bgp(cfg))
    end
    def create_ipsec(cfg)
      IpsecDelegate.new(@flavour.create_ipsec(cfg))
    end
  end


  def self.add(flavour)
    puts "setup flavour #{flavour.name}"
    @flavours[flavour.name.downcase] = FlavourDelegate.new(flavour)
  end

  @aspects = []
  def self.add_aspect(aspects)
    @aspects << aspects
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
