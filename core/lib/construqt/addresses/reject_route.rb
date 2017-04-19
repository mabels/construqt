module Construqt
  class Addresses
    class RejectRoute
      attr_reader :dst_addr_or_tag, :options, :address, :routing_table
      def initialize(dst_addr_or_tag, options, address, routing_table)
        @dst_addr_or_tag = dst_addr_or_tag
        @options = options
        @address = address
        @routing_table = routing_table
      end

      def metric
        @options['metric']
      end

      def is_global?
        true
      end

      def resolv
        ret = []
        dst_parse = Construqt::Tags.parse(self.dst_addr_or_tag)
        throw "routing tag not allowed in dst #{self.dst_addr_or_tag}" if dst_parse['!']
        routing_table = self.routing_table || ""
        ips = dst_parse[:first] && IPAddress.parse(dst_parse[:first])
        ips_v4 = Construqt::Tags.ips_adr(self.dst_addr_or_tag, Construqt::Addresses::IPV4)
        if ips && ips.ipv4?
          ips_v4.push(ips)
        end
        ips_v6 = Construqt::Tags.ips_adr(self.dst_addr_or_tag, Construqt::Addresses::IPV6)
        if ips && ips.ipv6?
          ips_v6.push(ips)
        end
        @address.ips.each do |adr|
            IPAddress::summarize(*((adr.ipv4? && ips_v4) or (adr.ipv6? && ips_v6) or [])).each do |dst|
              ret << RejectRoute.new(dst, @options, @address, @routing_table)
            end
        end
        ret
      end
    end
  end
end
