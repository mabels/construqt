module Construqt
  module Firewalls
    module ToDestFromSource
      # NAT only ipv4
      class IpWithPort
        attr_reader :ip, :port
        def initialize(ip, port)
          @ip = ip
          @port = port
        end
        def to_s
          if port
            "#{ip.to_s}:#{port}"
          else
            ip.to_s
          end
        end
      end

      def to_source(val=:my_first)
        @to_source = IpWithPort.new(val, nil)
        self
      end

      def _to_dest_to_source(val)
        addr = nil
        if defined?(val) && val.ip == :my_first
          ip = self.attached_interface.address.v4s.first
          if ip
            addr = IpWithPort.new(ip, val.port)
          end
        elsif defined?(val) && val && !val.ip.strip.empty?
          addr = IpWithPort.new(
            FromTo.resolver(val.ip, Construqt::Addresses::IPV4).first.ip_addr, val.port)

        end
        addr ?  [addr] : []
      end

      def get_to_source
        _to_dest_to_source(@to_source)
      end

      def to_dest(val=:my_first, dest_port=nil)
        @to_dest = IpWithPort.new(val, dest_port)
        self
      end

      def get_to_dest
        _to_dest_to_source(@to_dest)
      end
    end
  end
end
