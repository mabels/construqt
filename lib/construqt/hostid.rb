module Construqt

  class HostId
    attr_accessor :interfaces
    def self.create(&block)
      a = HostId.new()
      a.interfaces=[]
      block.call(a)
      return a
    end

    def first_ipv6!
      self.interfaces.each do |i|
        next unless i.address
        return i.address if i.address.first_ipv6
      end

      nil
    end

    def first_ipv6
      ret = first_ipv6!
      throw "first_ipv6 failed #{self.interfaces.first.host.name}" unless ret
      ret
    end

    def first_ipv4!
      self.interfaces.each do |i|
        next unless i.address
        return i.address if i.address.first_ipv4
      end

      nil
    end

    def first_ipv4
      ret = first_ipv4!
      throw "first_ipv4 failed #{self.interfaces.first.host.name}" unless ret
      ret
    end
  end
end
