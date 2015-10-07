
module Construqt
  module Flavour
    module Nixian
      NIXIAN_FACTORY = {}

      class DialectFactory
        attr_reader :dialect
        def initialize(dialect)
          @dialect = dialect
        end

        def name
          @dialect.name
        end

        def create_host(name, cfg)
          cfg['name'] = name
          cfg['result'] = nil
          host = @dialect::Host.new(cfg)
          host.result = @dialect::Result.new(host)
          host
        end

        def create_interface(name, cfg)
          cfg['name'] = name
          cfg['host'].flavour.flavour.dialect.clazz(cfg['clazz']).new(cfg)
        end

        def ipsec
          @dialect.ipsec
        end

        def bgp
          @dialect.bgp
        end

        def clazzes
          @dialect.clazzes
        end

        def create_bgp(cfg)
          @dialect.create_bgp(cfg)
        end

        def create_ipsec(cfg)
          @dialect.create_ipsec(cfg)
        end

      end

      class Factory
        def initialize(dialect)
          @dialect = dialect
        end

        def name
          @dialect.flavour_name
        end

        def factory(cfg)
          FlavourDelegate.new(
            DialectFactory.new(NIXIAN_FACTORY[cfg['dialect']] || @dialect)
          )
        end
      end



      def self.add(dialect)
        NIXIAN_FACTORY[dialect.name] = dialect
        if dialect.respond_to?(:flavour_name)
          factory = Factory.new(dialect)
          Flavour.add(factory)
          Construqt.logger.info "add dialect by name #{dialect.name} and flavour #{dialect.flavour_name}"
        else
          Construqt.logger.info "add dialect by name #{dialect.name}"
        end
      end


      def self.name
        'nixian'
      end
      def self.flavour_name
        'nixian'
      end

      Flavour.add(Factory.new(self))

    end
  end
end


