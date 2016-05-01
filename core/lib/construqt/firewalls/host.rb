module Construqt
  module Firewalls
    class Host
      include Ipv4Ipv6
      include AttachInterface
      attr_reader :firewall, :rules
      attr_accessor :interface
      def initialize(firewall)
        @firewall = firewall
        @rules = []
      end

      def entry!
        ret = HostEntry.new(self)
        ret.attached_interface = self.attached_interface
        ret
      end

      def add
        entry = self.entry!
        #puts "ForwardEntry: #{@firewall.name} #{entry.request_only?} #{entry.respond_only?}"
        @rules << entry
        entry
      end
    end
  end
end
