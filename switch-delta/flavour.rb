module Construct
  module SwitchDelta

    class Flavour
      @parsers={}
      @renderers={}
      class << self
        attr_accessor :parsers, :renderers
      end
    end

    class Host
      attr_accessor :name,:dialect
      def initialize(name, dialect)
        self.name=name
        self.dialect=dialect
      end
    end

  end
end
