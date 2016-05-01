module Construqt
  module Firewalls

    class FwIpAddress
      def merge(ip)
        FwIpAddress.new
          .set_ip_addr(ip_addr)
          .missing(@fwtoken, @family, @missing)
      end

      def missing(fwtoken, family, missing = true)
        @fwtoken = fwtoken
        @family = family
        @missing = missing
        self
      end

      def missing?
        @missing
      end

      def self.missing(fwtoken, family)
        FwIpAddress.new.missing(fwtoken, family)
      end

      def to_string
        missing? ? "[MISSING:#{@family}]" : ip_addr.to_string
      end

      def to_s
        "#<#{self.class.name}:#{self.object_id}:#{ip_addr.to_string}>"
      end

      def ip_addr
        @ip_addr
      end

      def set_ip_addr(ip)
        @ip_addr = ip
        self
      end

      def self.create(fwtoken, ips, ret)
        ips.each do |ip|
          if ip.kind_of?(FwIpAddress)
            ret << ip
          elsif ip.kind_of?(IPAddress) || ip.kind_of?(Addresses::CqIpAddress)
            ret << FwIpAddress.new.set_ip_addr(ip)
          else
            throw "unknown type #{ip.class.name}"
          end
        end

        ret
      end
    end
  end
end
