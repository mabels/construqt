module Construqt
  module Firewalls
    class Nat
      include Ipv4Ipv6
      include AttachInterface
      attr_reader :firewall, :rules
      attr_accessor :interface
      def initialize(firewall)
        @firewall = firewall
        @rules = []
      end

      def entry!
        ret = NatEntry.new(self)
        ret.attached_interface = self.attached_interface
        ret
      end

      def add
        entry = self.entry!
        @rules << entry
        entry
      end
    end
  end
end
