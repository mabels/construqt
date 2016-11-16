module Construqt
  class ServicesShadow
    def initialize(parent)
      throw "parent must be a Services" unless parent.kind_of?(Services)
      @parent = parent
      @me = Services.new(parent)
    end
    def flavour
      @parent.flavour
    end
    def find(name)
      @me.find!(name) || @parent.find(name)
    end
    def are_registered_by_instance?(srvs)
      @me.are_registered_by_instance?(srvs) ||
      @parent.are_registered_by_instance?(srvs)
    end

    def are_registered_by_name?(srvs)
      @me.are_registered_by_name?(srvs) ||
      @parent.are_registered_by_name?(srvs)
    end

    def each(&block)
      @me.each(&block)
      @parent.each(&block)
    end

    def add(srv)
      @me.add(srv)
      self
    end
  end
  class Services
    attr_reader :flavour#, :services
    def initialize(flavour)
      @flavour = flavour
      @services = { }
    end

    def shadow
      ServicesShadow.new(self)
    end

    def find!(name)
      name = name.class.name unless name.kind_of?(String)
      found = @services[name]
    end

    def find(name)
      found = find!(name)
      unless found
        binding.pry
        throw "service with name #{name} not found"
      end
      found
    end

    def are_registered_by_instance?(srvs)
      are_registered_by_name?(srvs.map{|i| i.class.name})
    end

    def are_registered_by_name?(srvs)
      # puts "#{srvs} #{@services.keys}"
      srvs.empty? || srvs.find{|s| @services[s] }
    end

    def each(&block)
      @services.values.each(&block)
    end

    def add(service_impl)
      srvs = [
        service_impl.service_type.name,
        service_impl.service_type.name.split("::").last
      ].sort.uniq
      throw "service names are registered #{srvs}" if are_registered_by_name?(srvs)
      # binding.pry if srvs.first == "BgpStartStop"
      service_impl.attach_service(self)
      srvs.each do |name|
        @services[name] = service_impl
      end
      self
    end

  end
end
