
  class Aiccu
    include Construqt::Util::Chainable
    attr_reader :name
    attr_accessor :services
    chainable_attr :username
    chainable_attr :password
    def initialize(name)
      @name = name
    end
  end

class Aiccu
  class Impl
    attr_reader :service_type
    def initialize
        @service_type = Aiccu
    end

    def attach_service(service)
      @service = service
    end
    def build_interface(host, ifname, iface, writer)
    end

  end

end

