module Construqt
  module Firewalls
    class Mangle
      @rules = []
      class Tcpmss
      end

      def tcpmss
        @rules << Tcpmss.new
      end
    end
  end
end
