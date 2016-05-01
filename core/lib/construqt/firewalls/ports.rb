module Construqt
  module Firewalls
    module Ports
      def sport(port)
        @sports ||= []
        @sports << port
        self
      end

      def sport_range(lowport, upport)
        @sports ||= []
        @sports << [lowport, upport]
        self
      end

      def get_sports
        @sports ||= []
      end

      def dport(port)
        @dports ||= []
        @dports << port
        self
      end

      def dport_range(lowport, upport)
        @dports ||= []
        @dports << [lowport, upport]
        self
      end

      def get_dports
        @dports ||= []
      end
    end
  end
end
