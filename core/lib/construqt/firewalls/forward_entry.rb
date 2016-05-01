module Construqt
  module Firewalls
    class ForwardEntry
      attr_accessor :attached_interface
      include Util::Chainable
      include FromTo
      include InputOutputOnly
      include TcpMss
      include Ports
      include ActionAndInterface
      include FromIsInOutBound
      include Log
      include Protocols

      chainable_attr :connection
      chainable_attr :link_local

      def link_local(link_local = true)
        @link_local = link_local
        self
      end

      def link_local?
        @link_local
      end

      attr_reader :block
      def initialize(block)
        @block = block
      end
    end
  end
end
