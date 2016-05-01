module Construqt
  module Firewalls
    module Ipv4Ipv6
      def ipv6
        @family = Construqt::Addresses::IPV6
        self
      end

      def ipv6?
        if !defined?(@family)
          true
        else
          @family == Construqt::Addresses::IPV6
        end
      end

      def ipv4
        @family = Construqt::Addresses::IPV4
        self
      end

      def ipv4?
        if !defined?(@family)
          true
        else
          @family == Construqt::Addresses::IPV4
        end
      end
    end
  end
end
