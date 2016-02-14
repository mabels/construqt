module Construqt
  module Ipsecs
    class User
      attr_reader :name, :psk
      def initialize(name, psk)
        @name = name
        @psk = psk
      end
    end
  end
end
