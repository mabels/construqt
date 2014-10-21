
module Construct
class Addresses

  UNREACHABLE = :unreachable
  LOOOPBACK = :looopback
  DHCPV4 = :dhcpv4
  DHCPV6 = :dhcpv6
  IPV4 = :ipv4
  IPV6 = :ipv6

  def initialize(network)
    @network = network
    @Addresses = []
  end
  def network
    @network
  end

  class Address
    attr_accessor :host
    attr_accessor :interface
    attr_accessor :ips
    attr_accessor :tags
    def dhcpv4?
      @dhcpv4
    end
    def dhcpv6?
      @dhcpv6
    end
    def loopback?
      @loopback
    end
    def initialize()
      self.ips = []
      self.host = nil
      self.interface = nil
      self.routes = []
      self.tags = []
      @loopback = @dhcpv4 = @dhcpv6 = false
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

    def merge_tag(name, &block)
      Construct::Tags.add(([name]+self.tags).join("#")) { |name| block.call(name) }
    end

    def tag(tag)
      self.tags << tag
      self
    end

    def set_name(xname)
      (@name, obj) = self.merge_tag(xname) { |xname| self }
      self
    end
    def name=(name)
      @name = name
    end
    def name
      return @name if @name
      return "#{interface.name}-#{interface.host.name}" if interface
      return host.name if host
      throw "unreferenced address #{self.inspect}"  
    end
    def add_ip(ip, region = "")
      throw "please give a ip #{ip}" unless ip 
      if ip
#puts ">>>>> #{ip} #{ip.class.name}"
        if DHCPV4 == ip
          @dhcpv4 = true
        elsif DHCPV6 == ip
          @dhcpv6 = true
        elsif LOOOPBACK == ip
          @loopback = true
        else
          (unused, ip) = self.merge_tag(ip) { |ip| IPAddress.parse(ip) }
          self.ips << ip
        end
      end
      self
    end
    @nameservers = []
    def add_nameserver(ip)
      @nameservers << IPAddress.parse(ip)
      self
    end
    attr_accessor :routes
    def add_routes(addr_s, via, options = {})
      addrs = addr_s.kind_of?(Array) ? addr_s : [addr_s]
      addrs.each{|addr| addr.ips.each {|i| add_route(i.to_string, via, options) } }
      self
    end
    def add_route(dst, via, option = {})
      #puts "DST => "+dst.class.name+":"+dst.to_s
      (unused, dst) = self.merge_tag(dst) { |dst| IPAddress.parse(dst) }
      metric = option['metric']
      if via == UNREACHABLE
        via = nil
        type = 'unreachable'
      else
        if via.nil?
          via = nil
        else
          via = IPAddress.parse(via) 
          throw "different type #{dst} #{via}" unless dst.ipv4? == via.ipv4? && dst.ipv6? == via.ipv6?
        end
        type = nil
      end
      self.routes << OpenStruct.new("dst" => dst, "via" => via, "type" => type, "metric" => metric)
      self
    end
    def to_s
      "<Address:Address #{@name}=>#{self.ips.map{|i| i.to_s}.join(":")}>"
    end
  end
  def create
    ret = Address.new()
    @Addresses << ret
    ret
  end
  def tag(tag)
    create.tag(tag)
  end
  def add_ip(ip, region = "")
    create.add_ip(ip, region)
  end
  def add_route(dest, via = nil)
    create.add_route(dest, via)
  end
  def set_name(name)
    create.set_name(name)
  end
  def all
    @Addresses
  end
end
end
