require_relative("ciscian/deploy_template")
require_relative("ciscian/result")
require_relative("ciscian/bond")
require_relative("ciscian/device")
require_relative("ciscian/host")
require_relative("ciscian/notimplemented")
require_relative("ciscian/vlan")
require_relative("ciscian/nested_section")
require_relative("ciscian/pattern_based_verb")
require_relative("ciscian/range_verb")
require_relative("ciscian/singlenestedverb")

module Construqt
  module Flavour
    class Ciscian
      def name
        'ciscian'
      end

      class Factory
        def name
          'ciscian'
        end
        def factory(cfg)
          FlavourDelegate.new(Ciscian.new)
        end
      end

      Construqt::Flavour.add(Factory.new)

      DIALECTS={}
      def self.dialects
        DIALECTS
      end

      def self.add_dialect(dialect)
        path = dialect.name.split("::")
        Construqt.logger.info "add_dialect #{dialect.name} #{Construqt::Util.snake_case(path[-2])}:#{Construqt::Util.snake_case(path[-1])}"
        DIALECTS[Construqt::Util.snake_case(path[-2])] ||= {}
        DIALECTS[Construqt::Util.snake_case(path[-2])][Construqt::Util.snake_case(path[-1])] = dialect
      end

      def clazzes
        {
          "opvn" => NotImplemented,
          "bond" => Bond,
          "bridge" => NotImplemented,
          "gre" => NotImplemented,
          "vrrp" => NotImplemented,
          "template" => NotImplemented,
          "vlan" => Vlan,
          "host" => Host,
          "device"=> Device,
          "result" => Result
        }
      end

      def clazz(name)
        ret = self.clazzes[name]
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
        #cfg['name'] = name
        #Interface.new(cfg)
      end
    end
  end
end
