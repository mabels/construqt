
module Construqt

  class Hosts
    module Lxc
      RECREATE = "recreate"
      RESTART = "restart"
      KILLSTOP = "killstop"
    end

    class Vagrant
      def net(net)
        @net = net
        self
      end
      def get_net
        @net
      end
      def auto_config(mode = false)
        @auto_config = mode
        self
      end
      def get_auto_config
        @auto_config
      end

      def ssh_host_port(port)
        @ssh_host_port = port
        self
      end
      def get_ssh_host_port
        @ssh_host_port
      end
    end

  	attr_reader :region
    def initialize(region)
      @region = region
      @hosts = {}
      @default_pwd = SecureRandom.urlsafe_base64(24)
    end

    def set_default_password(pwd)
      @default_pwd = pwd
    end

    def default_password
      @default_pwd
    end

    def get_hosts()
      @hosts.values
    end

    def del(name)
      host = @hosts[name]
      return nil unless host
      @hosts.delete(name)
      host
    end

    def add(host_name, cfg, &block)
      (host_name, host) = Construqt::Tags.add(host_name) { |name| add_internal(name, cfg) { |h| block.call(h) } }
      host
    end

    class HostInterfaces < Hash
      def bind_host(host)
        @host = host
      end
      def find_by_name(name)
        self[name] || throw("Interface with name [#{name}] not found on host [#{@host.name}]")
      end
    end

    def add_internal(name, cfg, &block)
      #binding.pry
      throw "id is not allowed" if cfg['id']
      throw "configip is not allowed" if cfg['configip']
      throw "Host with the name #{name} exisits" if @hosts[name]
      cfg['interfaces'] = HostInterfaces.new
      cfg['id'] ||=nil
      cfg['configip'] ||=nil

      cfg['name'] = name
      cfg['dns_server'] ||= false
      cfg['result'] = nil
      cfg['shadow'] ||= nil
      cfg['flavour'] = Flavour.factory(cfg)
      #		cfg['clazz'] = cfg['flavour'].clazz("host")
      throw "flavour #{cfg['flavour']} for host #{name} not found" unless cfg['flavour']
      cfg['region'] = @region
      host = cfg['flavour'].create_host(name, cfg)
      block.call(host)
      host.interfaces.bind_host(host)
      throw "host attribute id is required" unless host.id.kind_of? HostId
      throw "host attribute configip is required" unless host.configip.kind_of? HostId

      if (host.id.first_ipv4! && !host.id.first_ipv4!.dhcpv4?) ||
          (host.id.first_ipv6! && !host.id.first_ipv6!.dhcpv6?)
        adr = nil
        if host.id.first_ipv4!
          adr = (adr || region.network.addresses.create).add_ip(host.id.first_ipv4.first_ipv4.to_s).set_name(host.name)
        end

        if host.id.first_ipv6!
          adr = (adr || region.network.addresses.create).add_ip(host.id.first_ipv6.first_ipv6.to_s).set_name(host.name)
        end

        adr = region.network.addresses.create unless adr
        adr.host = host if adr
      end

      @hosts[name] = host
    end

    def find!(name)
      @hosts[name]
    end

    def find(name)
      ret = @hosts[name]
      throw "host not found #{name}" unless ret
      ret
    end

    def build_config(hosts = nil)
      (hosts || @hosts.values).each do |host|
        host.build_config(host, nil)
      end
    end

    def commit(hosts = nil)
      (hosts || @hosts.values).each { |h| h.commit }
      Flavour.call_aspects("completed", nil, nil)
    end
  end
end
