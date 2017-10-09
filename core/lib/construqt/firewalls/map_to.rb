module Construqt
  module Firewalls
    module MapTo

      def map_to(val=:my_first)
        throw "one map_to per rule" if defined?(@map_to)
        @map_to = val
        self
      end

      def _map_to(family, val)
        ip = nil
        if val.nil?
          return []
        end
        if val == :my_first
          ip = if family == Construqt::Addresses::IPV4
            self.attached_interface.address.v4s.first
          else
            self.attached_interface.address.v6s.first
          end
        elsif !val.strip.empty?
          ip = FromTo.resolver(val, family).first.ip_addr
        end
        ip ?  [ip] : []
      end

      def get_map_to(family)
        _map_to(family, @map_to)
      end

    end
  end
end
