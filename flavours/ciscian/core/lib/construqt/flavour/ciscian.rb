require_relative('ciscian/deploy_template')
require_relative('ciscian/result')
require_relative('ciscian/bond')
require_relative('ciscian/device')
require_relative('ciscian/host')
require_relative('ciscian/notimplemented')
require_relative('ciscian/vlan')
require_relative('ciscian/nested_section')
require_relative('ciscian/pattern_based_verb')
require_relative('ciscian/range_verb')
require_relative('ciscian/singlenestedverb')

module Construqt
  module Flavour
    class Ciscian

      DIRECTORY = File.dirname(__FILE__)

      class Factory < Construqt::Flavour::DialectFactoryBase
        def dialect_factory
          DialectFactory
        end

        def name
          'ciscian'
        end
      end

      class DialectFactory
        attr_reader :dialect
        def initialize(dialect)
          @dialect = dialect
        end
        def name
          "ciscian"
        end
        # Construqt::Flavour.add(Factory.new)

        # def initialize
        #   @dialects={}
        # end
        #
        # def add_dialect(dialect)
        #   path = dialect.name.split("::")
        #   Construqt.logger.info "add_dialect #{dialect.name} #{Construqt::Util.snake_case(path[-2])}:#{Construqt::Util.snake_case(path[-1])}"
        #   @dialects[Construqt::Util.snake_case(path[-2])] ||= {}
        #   @dialects[Construqt::Util.snake_case(path[-2])][Construqt::Util.snake_case(path[-1])] = dialect
        # end

        def clazzes
          {
            'opvn' => NotImplemented,
            'bond' => Bond,
            'bridge' => NotImplemented,
            'gre' => NotImplemented,
            'vrrp' => NotImplemented,
            'template' => NotImplemented,
            'vlan' => Vlan,
            'host' => Host,
            'device' => Device,
            'result' => Result
          }
        end

        def clazz(name)
          ret = clazzes[name]
          throw "class not found #{name}" unless ret
          ret
        end

        def create_host(name, cfg)
          cfg['name'] = name
          cfg['result'] = nil
          host = Host.new(cfg)
          host.result = Result.new(host)
          host
        end

        def create_interface(name, cfg)
          cfg['name'] = name
          clazz(cfg['clazz']).new(cfg)
          # cfg['name'] = name
          # Interface.new(cfg)
        end
    end
    end
  end
end
