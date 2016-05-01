module Construqt
  module Firewalls
    module FromIsInOutBound
      def from_is_outside?
        @from_is == :outside
      end

      def from_is_inside?
        @from_is == :inside
      end

      def from_is_inside
        @from_is = :inside
        self
      end

      def from_is_outside
        @from_is = :outside
        self
      end
    end
  end
end
