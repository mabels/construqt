module Construqt
  module Tunnels
    class EndpointAddress
      include Construqt::Util::Chainable
      attr_reader :host
      chainable_attr_value :interface

      def initialize(host)
        @host = host
      end

      def address(str_addr)
        @address = @host.region.network.addresses.create.add_ip(str_addr)
        self
      end

      def service_ip(str_addr)
        @service_address = @host.region.network.addresses.create.add_ip(str_addr)
        self
      end

      def valid?()
        get_interface || @address || @service_address
      end

      def get_address
        @address
      end

      def get_service_ip
        @service_address
      end

      def get_service_address
        @service_address || get_local_address
      end

      def get_local_address
        get_address || get_interface.address
      end

      def get_address_ipv6
        get_service_address.first_ipv6
      end

      def get_address_ipv4
        get_service_address.first_ipv4
      end

    end
  end
end
