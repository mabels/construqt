module Construqt
  class Addresses
    class Networks
      def initialize
        @networks = []
      end

      def add(net)
        @networks << net
      end

      def v4s
        IPAddress::summarize(@networks.select{|i| i.ipv4?})
      end

      def v6s
        IPAddress::summarize(@networks.select{|i| i.ipv6?})
      end
    end
  end
end
