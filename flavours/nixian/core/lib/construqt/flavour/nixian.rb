
module Construqt
  module Flavour
    module Nixian

      class DialectFactory
        attr_reader :dialect
        def initialize(dialect)
          @dialect = dialect
        end

        def name
          @dialect.name
        end

        def create_host(name, cfg)
          @dialect.create_host(name, cfg)
        end

        def create_interface(name, cfg)
          cfg['name'] = name
          cfg['host'].flavour.flavour.dialect.clazz(cfg['clazz']).new(cfg)
        end

        def add_host_services(srvs)
          @dialect.add_host_services(srvs)
        end

        def add_interface_services(srvs)
          @dialect.add_interface_services(srvs)
        end

        def services_factory
          @dialect.services_factory
        end

        #def ipsec
        #  @dialect.ipsec
        #end

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

      class Factory < Construqt::Flavour::DialectFactoryBase
        def initialize
          super
          Construqt::Flavour::Nixian::Services.register(services_factory)
        end

        def name
          "nixian"
        end

        def dialect_factory
          DialectFactory
        end

      end



#      def self.add(dialect)
#        @nixian_factory[dialect.name] = dialect
#        if dialect.respond_to?(:flavour_name)
#          factory = Factory.new(dialect)
#          Flavour.add(factory)
#          Construqt.logger.info "add dialect by name #{dialect.name} and flavour #{dialect.flavour_name}"
#        else
#          Construqt.logger.info "add dialect by name #{dialect.name}"
#        end
#      end


#      def self.name
#        'nixian'
#      end
#      def self.flavour_name
#        'nixian'
#      end

    end
  end
end
