module Construqt
  class Ntp
    attr_reader :servers
    def initialize
      @servers = Construqt::Addresses::Address.new(self)
    end
    def add_server(address)
      if address.kind_of?(Construqt::Addresses::Address)
        @servers.add_addr(address)
      else
        address.each { |ip| @servers.add_ip(ip.to_string) }
      end
      self
    end
    def timezone(zone)
      @zone = zone
      self
    end
    def get_timezone
      @zone || "MET"
    end
  end
end
