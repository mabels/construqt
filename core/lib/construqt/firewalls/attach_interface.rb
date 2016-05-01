module Construqt
  module Firewalls
    module AttachInterface
      attr_reader :attached_interface
      def _rules_attach_iface(iface)
        @attached_interface = iface
        @rules = @rules.map do |entry|
          ret = entry.clone
          ret.attached_interface = iface
          ret
        end

        self
      end

      def attach_iface(iface)
        ret = self.clone
        ret._rules_attach_iface(iface)
      end
    end
  end
end
