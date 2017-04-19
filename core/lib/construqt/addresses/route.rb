module Construqt
  class Addresses
    class RaRoute
      def resolv
        []
      end
      def is_global?
        false
      end
    end

    class Route
      def initialize(dst_ips, via_ips, options)
        @dst_ips = dst_ips
        @via_ips = via_ips
        @options = options
      end

      def is_global?
        false
      end

      def resolv
        ret = []
        @via_ips.each do |via|
          if via == UNREACHABLE
            via = nil
            type = 'unreachable'
          else
            type = nil
          end

          @dst_ips.each do |dst|
            ret << DirectRoute.new(dst, via, type, @options['metric'], @options)
          end
        end
        ret
      end
    end
  end
end
