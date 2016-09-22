module Construqt
  class Addresses
    # hier frieht die hoelle zu!!!
    class CqIpAddress
      attr_reader :ipaddr, :container, :options, :routing_table
      def initialize(ipaddr, container, options, routing_table)
        @ipaddr = ipaddr
        @container = container
        @options = options
        @routing_table = routing_table
      end

      def <=>(oth)
        if oth.kind_of?(CqIpAddress)
          ret = self.ipaddr <=> oth.ipaddr
          #puts "CqIpAddress <=> #{self.ipaddr.to_string} <#{ret}> #{oth.ipaddr}"
        else
          ret = self.ipaddr <=> oth
          #puts "IpAddress <=> #{self.ipaddr.to_string} <#{ret}> #{oth}"
        end

        ret
      end

      def ip_bits
        @ipaddr.ip_bits
      end
      def host_address
        @ipaddr.host_address
      end

      def is_ipv4
        @ipaddr.ipv4?
      end
      def ipv4?
        @ipaddr.ipv4?
      end

      def is_ipv6
        @ipaddr.ipv6?
      end
      def ipv6?
        @ipaddr.ipv6?
      end

      def is_unspecified
        @ipaddr.is_unspecified
      end

      def include?(a)
        @ipaddr.include?(a)
      end

      def prefix
        @ipaddr.prefix
      end

      def network
        @ipaddr.network
      end

      def to_i
        @ipaddr.to_i
      end

      def to_s
        @ipaddr.to_s
      end

      def to_string
        @ipaddr.to_string
      end

      def to_u32
        @ipaddr.to_u32
      end

      def to_u128
        @ipaddr.to_u128
      end

      def first
        @ipaddr.first
      end

      def last
        @ipaddr.last
      end

      def broadcast
        @ipaddr.broadcast
      end

      def groups
        @ipaddr.groups
      end

      def compressed
        @ipaddr.compressed
      end

      def reverse
        @ipaddr.reverse
      end

      def address
        @ipaddr.address
      end

      def netmask
        @ipaddr.netmask
      end

#      def map(&block)
#        @ipaddr.map{|i| block.call(i) }
#      end
    end
  end
end
