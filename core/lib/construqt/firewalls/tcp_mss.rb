module Construqt
  module Firewalls
    module TcpMss
      def mss(mss)
        ipv4_mss(mss)
        ipv6_mss(mss-((2*(128-32))/8))
        self
      end

      def ipv6_mss(mss)
        @ipv6_mss = mss
        self
      end

      def get_ipv6_mss
        @ipv6_mss
      end

      def ipv4_mss(mss)
        @ipv4_mss = mss
        self
      end

      def get_ipv4_mss
        @ipv4_mss
      end
    end
  end
end
