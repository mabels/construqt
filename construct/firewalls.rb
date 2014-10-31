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
      @raw = Raw.new(self)
      @nat = Nat.new(self)
      @forward = Forward.new(self)
    end
    def name
      @name
    end
    class Raw
      attr_reader :firewall
      def initialize(firewall)
        @firewall = firewall
        @rules = []
      end
      class RawEntry
        include Util::Chainable
        chainable_attr :prerouting, true, false, lambda{|i| @output = false; input_only(true); output_only(false) }
        chainable_attr :input_only, true
        chainable_attr :output, true, false, lambda {|i| @prerouting = false; input_only(false); output_only(true) }
        chainable_attr :output_only, true
        chainable_attr :interface
        chainable_attr_value :from_net, nil
        chainable_attr_value :to, nil
        chainable_attr_value :to_net, nil
        chainable_attr_value :action, nil
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
      attr_reader :firewall, :rules
      def initialize(firewall)
        @firewall = firewall
        @rules = []
      end
      class NatEntry
        include Util::Chainable
        chainable_attr :prerouting, true, false, lambda{|i| @postrouting = false; input_only(true); output_only(false) }
        chainable_attr :input_only
        chainable_attr :postrouting, true, false, lambda{|i| @prerouting = false; input_only(false); output_only(true) }
        chainable_attr :output_only
        chainable_attr :to_source
        chainable_attr :interface
        chainable_attr_value :from_net, nil
        chainable_attr_value :to_net, nil
        chainable_attr_value :action, nil
      end
      def add
        entry = NatEntry.new
        @rules << entry
        entry
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
      attr_reader :firewall, :rules
      def initialize(firewall)
        @firewall = firewall
        @rules = []
      end
      class ForwardEntry
        include Util::Chainable
        chainable_attr :interface
        chainable_attr :connection
        chainable_attr :input_only, true, true
        chainable_attr :output_only, true, true
        chainable_attr :connection
        chainable_attr :tcp
        chainable_attr :udp
        chainable_attr_value :log, nil
        chainable_attr_value :from_net, nil
        chainable_attr_value :to_net, nil
        chainable_attr_value :action, nil
        def port(port)
          @ports ||= []
          @ports << port
          self
        end
        def get_ports
          @ports ||= []
        end
      end
      def add
        entry = ForwardEntry.new
        #puts "ForwardEntry: #{@firewall.name} #{entry.input_only?} #{entry.output_only?}"
        @rules << entry
        entry
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
