module Construqt
  module Networks

    class Network
      def initialize(name)
        @name = name
        @networks = []
        @domain = "construqt.org"
        @contact = "soa@construqt.org"
        @addresses = Construqt::Addresses.new(self)
        @dns_resolver = nil
      end

      def addresses
        @addresses
      end

      def add_blocks(*nets)
        nets.each do |net|
          @networks << IPAddress.parse(net)
        end
      end

      def networks
        @networks
      end

      def to_network(ip)
        ret = (@networks.find{ |my| (ip.ipv6? == my.ipv6? && ip.ipv4? == my.ipv4?) && my.include?(ip) } || ip.network)
        ret
      end

      def set_dns_resolver(nameservers, search)
        @dns_resolver = OpenStruct.new :nameservers => nameservers, :search => search
      end

      def dns_resolver
        @dns_resolver
      end

      def set_domain(domain)
        @domain = domain
      end

      def domain
        @domain
      end

      def set_contact(contact)
        @contact = contact
      end

      def contact
        @contact
      end

      #    def domain(name)
      #      _fqdn = self.fqdn(name)
      #      _fqdn[_fqdn.index('.')+1..-1]
      #    end

      def fqdn(name)
        throw "name must set" unless name
        _name = name.gsub(/[\s_]+/, '-')
        return "#{_name}.#{self.domain}" unless _name.include?('.')
        return _name
      end
    end

    @networks = {}
    def self.add(name)
      throw "network with name #{name} exists" if @networks[name]
      @networks[name] = Network.new(name)
    end
  end
end
