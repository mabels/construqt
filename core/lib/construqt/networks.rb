module Construqt
  module Networks


    class Network
      attr_reader :address, :phone, :ntp, :routing_tables, :cert_store, :name
      def initialize(name)
        throw "network needs a name" unless name
        @name = name
        @networks = []
        @domain = "construqt.org"
        @contact = "soa@construqt.org"
        @addresses = Construqt::Addresses.new(self)
        @dns_resolver = Construqt::Dns.new(self)
        @ntp = Construqt::Ntp.new
        @routing_tables = Construqt::RoutingTables.new(self)
        @cert_store = Construqt::CertStore.new(self)
      end

      def inspect
        "@<#{self.class.name}:#{self.object_id} name=#{@name} domain=#{@domain} "+
        " contact=#{@contact} networks=[#{@networks.map{|i| i.inspect }.join(",")}]"+
        " addresses=#{@addresses.inspect} "+
        " dns_resolver=#{@dns_resolver.inspect} "+
        " ntp=#{@ntp.inspect} "+
        " routing_tables=#{@routing_tables.inspect} "+
        " cert_store=#{@cert_store.inspect}>"
      end

      def set_address(post_address)
        @address = post_address
      end

      def set_phone(phone)
        @phone = phone
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
        @networks.find{ |my| (ip.ipv6? == my.ipv6? && ip.ipv4? == my.ipv4?) && my.include?(ip) }
      end

      def set_dns_resolver(nameservers, search = [])
        @dns_resolver.nameservers = nameservers
        @dns_resolver.search = search
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
        _name = name.gsub(/[\s_\.]+/, '-')
        return "#{_name}.#{self.domain}" unless _name.include?('.')
        return _name
      end
    end

    @networks = {}
    def self.add(name)
      throw "network with name #{name} exists" if @networks[name]
      @networks[name] = Network.new(name)
    end

    def self.del(name)
      @networks.delete(name)
    end
  end
end
