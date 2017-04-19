module Construqt
  class Addresses
    class Routes
      attr_reader :routes
      def initialize
        @routes = []
      end

      def add_routes(routes)
        @routes += routes.routes
      end

      def add(route)
        unless route.kind_of?(Route) or
               route.kind_of?(TagRoute) or
               route.kind_of?(NearstRoute) or
               route.kind_of?(RaRoute) or
               route.kind_of?(RejectRoute)
          throw "route has to be a Route or TagRoute is #{route.class.name}"
        end
        @routes << route
      end

      def dst_networks
        ret = Networks.new
        self.each do |rt|
          ret.add(rt.dst)
        end

        ret
      end

      def find(&block)
        each_with_index do |rt, len|
          return true if block.call(rt, len)
        end
        return false
      end

      def each(&block)
        each_with_index(&block)
      end

      def each_with_index(&block)
        ret = []
        @routes.each do |route|
          route.resolv.each do |rt|
            #puts ">>>>#{route} #{rt}"
            ret << block.call(rt, ret.length)
          end
        end

        ret
      end
    end
  end
end
