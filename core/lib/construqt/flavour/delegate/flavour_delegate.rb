module Construqt
  module Flavour
    module Delegate
      class FlavourDelegate
        attr_reader :flavour
        def initialize(flavour)
          @flavour = flavour
        end

        def factory(cfg)
          #if @flavour.respond_to? :factory
            @flavour.factory(cfg)
          #else
          #  @flavour
          #end
        end

        def dialect
          @flavour.dialect
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
            'opvn' => OpvnDelegate,
            'gre' => GreDelegate,
            'host' => HostDelegate,
            'device' => DeviceDelegate,
            'vrrp' => VrrpDelegate,
            'bridge' => BridgeDelegate,
            'bond' => BondDelegate,
            'wlan' => WlanDelegate,
            'vlan' => VlanDelegate,
            'ipsecvpn' => IpsecVpnDelegate,
            'tunnel' => TunnelDelegate,
            # "result" => ResultDelegate,
            'template' => TemplateDelegate
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
    end
  end
end
