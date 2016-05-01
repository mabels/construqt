module Construqt
  module Firewalls

    module Log
      def log(val)
        @log = val
        self
      end

      def get_log
        @log
      end
    end
  end
end
