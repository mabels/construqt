module Construqt
  module Firewalls
    class FwToken
      attr_reader :type, :str
      def initialize(type, str = "")
        @type = type
        @str = str
      end

      def is_tag?
        @type == '#'
      end

      def is_literal?
        @type == '@'
      end
    end
  end
end
