module Construqt
  module Firewalls
    class NatEntry
      attr_accessor :attached_interface
      include FromTo
      include InputOutputOnly
      include Ports
      include Protocols
      include ToDestFromSource
      include ActionAndInterface
      include FromIsInOutBound

      def connection?
        false
      end

      def get_log
        nil
      end

      def link_local?
        false
      end

      attr_reader :block
      def initialize(block)
        @block = block
      end
    end
  end
end
