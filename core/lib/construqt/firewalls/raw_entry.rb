module Construqt
  module Firewalls
    class RawEntry
      attr_accessor :attached_interface
      include Protocols
      include ActionAndInterface
      include Ports
      include FromTo
      include Log
      include InputOutputOnly
      include FromIsInOutBound

      attr_reader :block
      def initialize(block)
        @block = block
      end
    end
  end
end
