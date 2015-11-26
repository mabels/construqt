
module Construqt
  module Flavour
    class Factory
      def initialize(region)
        @region = region
        @flavour_factory = {}
      end

      def call_aspects(type, *args)
        @region.aspects.each { |aspect| aspect.call(type, *args) }
      end

      def add(flavour)
        Construqt.logger.info "setup flavour for #{flavour.name}"
        @flavour_factory[flavour.name.downcase] = Delegate::FlavourDelegate.new(flavour)
      end

      def produce(cfg)
        throw "you need a flavour" unless cfg['flavour']
        name = cfg['flavour']
        ret = @flavour_factory[name.downcase]
        # unless ret
        #   require "construqt/flavour/#{name}.rb"
        #   ret = @flavour_factory[name.downcase]
        # end
        throw "flavour not found #{name}" unless ret
        ret.factory(cfg)
      end

      def parser(flavour, dialect, prefix = nil)
        @flavour_factory[flavour].flavour::Result.new(
          OpenStruct.new(dialect: dialect, fname: prefix, interfaces: {}))
      end
    end
  end
end
