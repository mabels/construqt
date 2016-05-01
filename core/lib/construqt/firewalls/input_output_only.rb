module Construqt
  module Firewalls
    module InputOutputOnly
      # the big side effect

      def request_only?
        (!@set && true) || @request_only
      end

      def respond_only?
        (!@set && true) || @respond_only
      end

      def request_only
        @set = true
        @request_only = true
        @respond_only = false
        self
      end

      def respond_only
        @set = true
        @request_only = false
        @respond_only = true
        self
      end

      def prerouting
        @output = false
        @prerouting = true
        request_only
        self
      end

      def prerouting?
        @prerouting
      end

      def output
        @output = true
        @prerouting = false
        respond_only
        self
      end

      def output?
        @output
      end

      def postrouting
        @input = false
        @postrouting = true
        request_only
        self
      end

      def postrouting?
        @postrouting
      end
    end
  end
end
