module Construqt
  class Addresses
    class DirectRoute
      attr_reader :dst, :via, :type, :metric, :options
      def is_global?
        false
      end
      def initialize(dst, via, type, metric, options)
        @dst = dst
        @via = via
        @type = type
        @metric = metric
        @options = options
      end
    end
  end
end
