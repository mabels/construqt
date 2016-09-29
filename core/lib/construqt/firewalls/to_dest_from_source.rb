module Construqt
  module Firewalls
    module ToDestFromSource
      # NAT only ipv4
      class IpWithPort
        attr_reader :ip, :port
        def initialize(ip, port)
          if ip.nil?
            raise "ip is nil"
          end
          @ip = ip
          @port = port
        end
        def has_port?
          !!@port
        end
        def to_s
          if port
            if ip.ipv6?
              "[#{ip.to_s}]:#{port}"
            else
              "#{ip.to_s}:#{port}"
            end
          else
            ip.to_s
          end
        end
      end

      def to_source(val=:my_first)
        @to_source = IpWithPort.new(val, nil)
        self
      end

      def _to_dest_to_source(family, val)
        addr = nil
        if defined?(val) && val.ip == :my_first
          ip = if family == Construqt::Addresses::IPV4
            self.attached_interface.address.v4s.first
          else
            self.attached_interface.address.v6s.first
          end
          if ip
            addr = IpWithPort.new(ip, val.port)
          end
        elsif defined?(val) && val && !val.ip.strip.empty?
          ret = FromTo.resolver(val.ip, family).first.ip_addr
          addr = IpWithPort.new(ret, val.port) unless ret.nil?
        end
        addr ?  [addr] : []
      end

      def get_to_source(family)
        _to_dest_to_source(family, @to_source)
      end

      def to_dest(val=:my_first, dest_port=nil)
        @to_dest = IpWithPort.new(val, dest_port)
        self
      end

      def get_to_dest(family)
        _to_dest_to_source(family, @to_dest)
      end
    end
  end
end
