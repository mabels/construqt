module Construqt
  module Firewalls
    class Raw
      include Ipv4Ipv6
      include AttachInterface
      attr_reader :firewall
      attr_accessor :interface
      def initialize(firewall)
        @firewall = firewall
        @rules = []
      end

      def entry!
        ret = RawEntry.new(self)
        ret.attached_interface = self.attached_interface
        ret
      end

      def add
        entry = self.entry!
        @rules << entry
        entry
      end

      def rules
        @rules
      end
    end
  end
end
