
module Construqt
  module Flavour

    FLAVOUR_FACTORY = {}

    class FlavourDelegate
      attr_reader :flavour
      def initialize(flavour)
        @flavour = flavour
      end

      def factory(cfg)
        if @flavour.respond_to? :factory
          @flavour.factory(cfg)
        else
          @flavour
        end
      end

      def name
        @flavour.name
      end

      def ipsec
        @flavour.ipsec
      end

      def bgp
        @flavour.bgp
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
          "wlan" => WlanDelegate,
          "vlan" => VlanDelegate,
          "ipsecvpn" => IpsecVpnDelegate,
          #"result" => ResultDelegate,
          "template" => TemplateDelegate
        }
      end

      def pre_clazzes(&block)
        @flavour.clazzes.each do |key, clazz|
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

    @aspects = []
    def self.add_aspect(aspect)
      Construqt.logger.info "setup aspect #{aspect.name}"
      @aspects << aspect
    end

    def self.del_aspect(aspect)
      @aspects = @aspects.select{|a| a.name != aspect }
    end

    def self.call_aspects(type, *args)
      @aspects.each { |aspect| aspect.call(type, *args) }
    end

    def self.add(flavour)
      Construqt.logger.info "setup flavour by #{flavour.name}"
      FLAVOUR_FACTORY[flavour.name.downcase] = FlavourDelegate.new(flavour)
    end


    def self.factory(cfg)
      name = cfg['flavour'] || 'ubuntu'
      ret = FLAVOUR_FACTORY[name.downcase]
      unless ret
        require "construqt/flavour/#{name}.rb"
        ret = FLAVOUR_FACTORY[name.downcase]
      end
      throw "flavour not found #{name}" unless ret
      ret.factory(cfg)
    end

    def self.parser(flavour, dialect, prefix = nil)
      FLAVOUR_FACTORY[flavour].flavour::Result.new(
        OpenStruct.new(:dialect => dialect, :fname => prefix, :interfaces => {}))
    end

  end
end
