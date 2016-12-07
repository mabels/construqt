
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
  class Factory
    attr_reader :machine
    def start(services_factory)
      @machine = services_factory.machine.service_type(Aiccu)
    end

    def produce(host, srv_inst, ret)
      Action.new
    end
  end

  class Action
    def build_interface(host, ifname, iface, writer)
    end
  end

end

