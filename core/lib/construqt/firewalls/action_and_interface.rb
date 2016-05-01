module Construqt
  module Firewalls
    module ActionAndInterface
      def action(val)
        @action = val
        self
      end

      def get_action
        @action
      end
    end
  end
end
