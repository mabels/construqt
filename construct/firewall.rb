module Construct

module Firewalls
  @firewalls = {}
  class Firewall
    attr_accessor :name
    class Raw
      @rules = []
      class Notrack << OpenStruct
        def initialize(cfg)
          super(cfg)
        end
      end
      def notrack(cfg)
        @rules << Notrack.new(cfg)
      end
    end
    def raw(&block)
      block.call(@raw)    
    end

    class Mangle
      @rules = []
      class Tcpmss
      end
      def tcpmss
        @rules << Tcpmss.new
      end
    end
    def mangle(&block)
      block.call(@mangle)
    end

    class Forward
      @rules = []
      class All < OpenStruct
      end
      def all(cfg)
        @rules << All.new(cfg)
      end
    end

    class Input
      class All
      end
      @rules = []
      def all(cfg)
        @rules << All.new(cfg)
      en
    end
    def initialize(name)
      self.name = name
      self.raw = Raw.new
      self.input = Input.new
    end
  end
  def self.add(name, &block)
    fw = @firewalls[name] = Firewall.new(name)
    block.call(fw)
    fw
  end
end
end
