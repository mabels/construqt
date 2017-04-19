require_relative 'addresses/cq_ip_address.rb'
require_relative 'addresses/networks.rb'
require_relative 'addresses/routes.rb'
require_relative 'addresses/route.rb'
require_relative 'addresses/direct_route.rb'
require_relative 'addresses/tag_route.rb'
require_relative 'addresses/nearst_route.rb'
require_relative 'addresses/reject_route.rb'
require_relative 'addresses/address.rb'
module Construqt
  class Addresses

    UNREACHABLE = :unreachable
    LOOOPBACK = :looopback
    DHCPV4 = :dhcpv4
    DHCPV6 = :dhcpv6
    RAV6 = :rav6
    IPV4 = :ipv4
    IPV6 = :ipv6

    def initialize(network)
      @network = network
      @Addresses = []
    end

    def network
      @network
    end

    def create
      ret = Address.new(@network)
      @Addresses << ret
      ret
    end

    def tag(tag)
      create.tag(tag)
    end

    def add_ip(ip, region = "")
      create.add_ip(ip, region)
    end

    def add_route(dest, via = nil, options = {})
      create.add_route(dest, via, options)
    end

    def set_name(name)
      create.set_name(name)
    end

    def all
      @Addresses
    end

    def v4_default_route(tag = "")
      nets = [(1..9),(11..126),(128..168),(170..171),(173..191),(193..223)].map do |range|
        range.to_a.map{|i| "#{i}.0.0.0/8"}
      end.flatten
      nets += (0..255).to_a.select{|i| i!=254}.map{|i| "169.#{i}.0.0/16" }
      nets += (0..255).to_a.select{|i| !(16<=i&&i<31)}.map{|i| "172.#{i}.0.0/16" }
      nets += (0..255).to_a.select{|i| i!=168}.map{|i| "192.#{i}.0.0/16" }

      v4_default_route = self.create
      v4_default_route.set_name(tag).tag(tag) if tag && !tag.empty?
      IPAddress::IPv4::summarize(*(nets.map{|i| IPAddress::IPv4.new(i) })).each do |i|
        v4_default_route.add_ip(i.to_string)
      end

      v4_default_route
    end
  end
end
