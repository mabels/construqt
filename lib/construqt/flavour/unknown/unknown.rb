
module Construqt
  module Flavour
    module Unknown
      def self.name
        'unknown'
      end

      Construqt::Flavour.add(self)

      class Device < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
        end
      end

      class Vrrp < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
        end
      end

      class Bond < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
        end
      end

      class Vlan < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
        end
      end

      class Bridge < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
        end
      end

      class Host < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def header(host)
        end

        def footer(host)
        end

        def build_config(host, unused)
        end
      end

      class Gre < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
        end
      end

      class Opvn < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(host, iface)
        end
      end

      class Template
        def initialize(cfg)
          super(cfg)
        end
      end

      class Result
        def initialize(host)
        end

        def commit
        end
      end

      #	class Interface < OpenStruct
      #		def initialize(cfg)
      #      super(cfg)
      #		end

      #		def build_config(host, iface)
      #      self.clazz.build_config(host, iface||self)
      #		end

      #	end
      #
      #
      def self.ipsec
        Ipsec
      end
      def self.bgp
        Bgp
      end
      def self.clazzes
        {
          "opvn" => Opvn,
          "gre" => Gre,
          "host" => Host,
          "device"=> Device,
          "vrrp" => Vrrp,
          "bridge" => Bridge,
          "template" => Template,
          "bond" => Bond,
          "vlan" => Vlan,
        }
      end

      def self.clazz(name)
        ret = self.clazzes[name]
        throw "class not found #{name}" unless ret
        ret
      end

      def self.create_host(name, cfg)
        cfg['name'] = name
        cfg['result'] = nil
        host = Host.new(cfg)
        host.result = Result.new(host)
        host
      end

      def self.create_interface(name, cfg)
        cfg['name'] = name
        clazz(cfg['clazz']).new(cfg)
      end

      class Bgp < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(unused, unused1)
        end
      end

      def self.create_bgp(cfg)
        Bgp.new(cfg)
      end

      class Ipsec < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def build_config(unused, unused1)
        end
      end

      def self.create_ipsec(cfg)
        Ipsec.new(cfg)
      end
    end
  end
end
