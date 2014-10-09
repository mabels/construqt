module Construct
module Addresses
  @networks = []

  UNREACHABLE = :unreachable

  def self.add_network(*nets)
    nets.each do |net|
      @networks << IPAddress.parse(net) 
    end
  end
  def self.networks
    @networks
  end
  def self.to_network(ip)
    ret = (@networks.find{ |my| (ip.ipv6? == my.ipv6? && ip.ipv4? == my.ipv4?) && my.include?(ip) } || ip.network)
    ret
  end


  @domain = "construct.org"
  def self.set_domain(domain)
    @domain = domain
  end
  def self.domain
    @domain
  end

  @contact = "soa@construct.org"
  def self.set_contact(contact)
    @contact = contact
  end
  def self.contact
    @contact
  end

  @Addresses = []
  class Address
    attr_accessor :host
    attr_accessor :interface
    attr_accessor :ips
    def initialize()
      self.ips = []
      self.host = nil
      self.interface = nil
      self.routes = []
      @name = nil
    end
    def v6s
      self.ips.select{|ip| ip.ipv6? }
    end
    def v4s
      self.ips.select{|ip| ip.ipv4? }
    end
    def first_ipv4
      v4s.first
    end
    def first_ipv6
      v6s.first
    end

    def set_name(name)
      @name = name
      self
    end
    def name=(name)
      @name = name
    end
    def domain
      fqdn[fqdn.index('.')+1..-1]
    end
    def fqdn
        _name = self.name.gsub(/[\s_]+/, '-')
        return "#{_name}.#{Addresses.domain}" unless _name.include?('.')
        return _name
    end
    def name
      return @name if @name
      return "#{interface.name}-#{interface.host.name}" if interface
      return host.name if host
      throw "unreferenced address #{self.inspect}"  
    end
    def add_ip(ip, region = "")
      ip = IPAddress.parse(ip)
      self.ips << ip
      self
    end
    @nameservers = []
    def add_nameserver(ip)
      @nameservers << IPAddress.parse(ip)
      self
    end
    attr_accessor :routes
    def add_routes(addr, via)
      addr.ips.each {|i| add_route(i.to_string, via) }
      self
    end
    def add_route(dst, via)
      dst = IPAddress.parse(dst)
      if via == UNREACHABLE
        via = nil
        type = 'unrechable'
      else
        via = IPAddress.parse(via) 
        type = nil
        throw "different type #{dst} #{via}" unless dst.ipv4? == via.ipv4? && dst.ipv6? == via.ipv6?
      end
      self.routes << OpenStruct.new("dst" => dst, "via" => via, "type" => type)
      self
    end
    def to_s
      "<Address:Address #{self.name}=>#{self.ips.map{|i| i.to_s}.inspect}>"
    end
  end
  def self.add_ip(ip, region = "")
    ret = Address.new().add_ip(ip, region)
    @Addresses << ret
    ret
  end
  def self.set_name(name)
    ret = Address.new().set_name(name)
    @Addresses << ret
    ret
  end
  def self.all
    @Addresses
  end
end
end
