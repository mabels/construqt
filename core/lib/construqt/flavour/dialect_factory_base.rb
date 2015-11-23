module Construqt
  module Flavour
    class DialectFactoryBase
      def initialize
        @dialect_factories = {}
      end

      def add_dialect(dialect_factory)
        @dialect_factories[dialect_factory.name] = dialect_factory
      end

      def name
        thow "need to implement name"
      end

      def dialect_factory
        thow "need to implement dialect_factory"
      end

      def factory(cfg)
        throw 'cfg must have a dialect' unless cfg['dialect']
        throw "dialect not found #{cfg['dialect']}" unless @dialect_factories[cfg['dialect']]
        Construqt::Flavour::Delegate::FlavourDelegate.new(
          dialect_factory.new(@dialect_factories[cfg['dialect']].produce(cfg))
        )
      end
    end
end
end
