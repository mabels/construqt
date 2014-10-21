module Construct

module Firewalls

  @firewalls = {}
  module Actions
    NOTRACK = :NOTRACK
    SNAT = :SNAT
    ACCEPT = :ACCEPT
    DROP = :DROP
  end

  class Firewall
    def initialize(name)
      @name = name
      @raw = Raw.new
      @nat = Nat.new
      @forward = Forward.new
    end
    class Raw
      class RawEntry
        extend Util::Chainable
        chainable_attr :prerouting
        chainable_attr :output
        chainable_attr :interface
        chainable_attr_value :from, nil
        chainable_attr_value :to, nil
        chainable_attr_value :action, nil
      end
      def initialize
        @rules = []
      end
      def add
        entry = RawEntry.new
        @rules << entry
        entry
      end
      def rules
        @rules
      end
    end
    def get_raw
      @raw
    end
    def raw(&block)
      block.call(@raw)
    end

    class Nat
      class NatEntry
        extend Util::Chainable
        chainable_attr :postrouting
        chainable_attr :prerouting
        chainable_attr :to_source
        chainable_attr :interface
        chainable_attr_value :from, nil
        chainable_attr_value :to, nil
        chainable_attr_value :action, nil
      end
      def initialize
        @rules = []
      end
      def add
        entry = NatEntry.new
        @rules << entry
        entry
      end
      def rules
        @rules
      end
    end
    def get_nat
      @nat
    end
    def nat(&block)
      block.call(@nat)    
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
      class ForwardEntry
        extend Util::Chainable
        chainable_attr :interface
        chainable_attr :connection
        chainable_attr_value :log, nil
        chainable_attr_value :from, nil
        chainable_attr_value :to, nil
        chainable_attr_value :action, nil
      end
      def initialize
        @rules = []
      end
      def add
        entry = ForwardEntry.new
        @rules << entry
        entry
      end
      def rules
        @rules
      end
    end
    def get_forward
      @forward
    end
    def forward(&block)
      block.call(@forward)    
    end

    class Input
      class All
      end
      @rules = []
      def all(cfg)
        @rules << All.new(cfg)
      end
    end
  end
  def self.add(name, &block)
    throw "firewall with this name exists #{name}" if @firewalls[name]
    fw = @firewalls[name] = Firewall.new(name)
    block.call(fw)
    fw
  end
  def self.find(name)
    ret = @firewalls[name]
    throw "firewall with this name #{name} not found" unless @firewalls[name]
    ret
  end

end
end
