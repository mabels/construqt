module Construqt
  module Firewalls
    module ToDestFromSource
      # NAT only ipv4
      def to_source(val=:my_first)
        @to_source = val
        self
      end

      def _to_dest_to_source(val)
        addr = nil
        if val == :my_first
          addr = self.attached_interface.address.v4s.first
        elsif defined?(val) && val && !val.strip.empty?
          addr = FromTo.resolver(val, Construqt::Addresses::IPV4).first.ip_addr
        end

        addr ?  [addr] : []
      end

      def get_to_source
        _to_dest_to_source(@to_source)
      end

      def to_dest(val=:my_first)
        @to_dest = val
        self
      end

      def get_to_dest
        _to_dest_to_source(@to_dest)
      end
    end
  end
end
