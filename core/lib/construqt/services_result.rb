module Construqt

  # class ServiceResult
  #   attr_reader :srv_instance
  #   def initialize(srv_instance)
  #     @srv_instance = srv_instance
  #   end
  # end

  class ResultTypeFactory
    attr_reader :result_type_instance, :instances
    def initialize(result_type)
      @result_type = result_type
      @instances = Set.new
    end
    def add_service_instance(srv_inst)
      @instances.add(srv_inst)
    end
    def produce_result(result_types, host)
      throw "only once per Factory" if @result_type_instance
      @result_type_instance = @result_type.new(result_types, host)
    end
    def each_instance(&block)
      @instances.each(&block)
    end
  end

  class ServiceType
    attr_reader :result_types, :service_producers
    def initialize
      @result_types = Set.new
      @service_producers = Set.new
    end
    def add_service_producer(srv_prod)
      @service_producers.add(srv_prod)
    end
    def add_result_types(rtypes)
      rtypes.each do |rt|
        @result_types.add(rt)
      end
    end
  end

  class ServiceInstanceProducer
    attr_reader :id, :srv_inst, :factory, :host, :iface, :instance
    def initialize(id, srv_inst, factory, host, iface)
      @id = id
      @srv_inst = srv_inst
      @factory = factory
      @host = host
      @iface = iface
    end
    def produce
      @instance = factory.produce(host, srv_inst, self)
    end

    def attach_result(res)
      throw "attach_result failed no instance" unless @instance
      @instance.respond_to?(:attach_result) and @instance.attach_result(res)
    end
  end

  class ResultTypeProducer
    attr_reader :result_type, :factory, :host, :iface, :instance, :service_instances
    def initialize(result_type, factory, host, iface)
      @result_type = result_type
      @factory = factory
      @host = host
      @iface = iface
      @service_instances = Set.new
    end
    def produce
      # binding.pry
      @instance = result_type.new
      @instance.respond_to?(:attach_host) && @instance.attach_host(host)
      @instance.respond_to?(:attach_interface) && @instance.attach_interface(iface)
    end
    def attach_result(rt)
      throw "attach_service failed no instance" unless @instance
      @instance.respond_to?(:attach_result) and @instance.attach_result(rt)
    end
    def attach_service(si)
      throw "attach_service failed no instance" unless @instance
      @instance.respond_to?(:attach_service) and @instance.attach_service(si)
    end
    def add_service_producer(srv_ins)
      @service_instances.add(srv_ins)
    end
  end

  class ResultTypes
    attr_reader :result_types, :service_types, :service_instances
    def initialize(host)
      @host = host
      @result_types = {}
      @service_instances = {}
      @service_types = {}
    end

    def inspect
      "#<#{self.class.name}:#{object_id} host=#{@host.name} "+
      "result_types=[#{@result_types.keys.map{|i| i.name}.join(",")}] "+
      "service_instances=[#{@service_instances.keys.join(",")}] "+
      "service_types=[#{@service_types.keys.join(",")}]>"
    end

    def add_service_instance(srv_inst, factory, host, iface)
      id = [srv_inst.object_id,host.object_id,iface.object_id].join(":")
      @service_instances[id] ||= ServiceInstanceProducer.new(id, srv_inst, factory, host, iface)
    end

    def add_result_type(srv_prod, factory, host, iface)
      factory.machine.result_types.map do |rt|
        binding.pry if rt ==  Construqt::Flavour::Nixian::Services::Result
        @result_types[rt] ||= ResultTypeProducer.new(rt, factory, host, iface)
        @result_types[rt].add_service_producer(srv_prod)
        @result_types[rt]
      end
    end

   def add(srv_inst, factory, host, iface = nil)
     srv_prod = add_service_instance(srv_inst, factory, host, iface)
     result_types = add_result_type(srv_prod, factory, host, iface)
     @service_types[srv_inst.class.name] ||= ServiceType.new
     @service_types[srv_inst.class.name].add_result_types(result_types)
     @service_types[srv_inst.class.name].add_service_producer(srv_prod)
   end

    def each(&block)
      @result_types.values.each(&block)
    end

    def find_by_service_type(service_type)
      key = service_type
      key = service_type.class.name unless key.kind_of?(String)
      key = service_type.name if key == "Class"
      ret = @service_types[key]
      unless ret
        binding.pry
        throw "find_by_service_instance failed for #{service_type}"
      end
      ret
    end

    #def self.attach_service(ref, srv_inst, ret)
    #  return unless impl.respond_to?(:result_type)
    #  ret.add_result_type(impl.result_type, srv_inst)
    #end

    def self.produce(host)
      ret = ResultTypes.new(host)
      # run through all service instance
      host.services.each do |srv_inst|
        ret.add(srv_inst, host.flavour.services_factory.find(srv_inst), host)
      end
      host.interfaces.values.each do |iface|
        iface.services.each do |srv_inst|
          ret.add(srv_inst, host.flavour.services_factory.find(srv_inst), host, iface)
        end
      end
      # create all instances onceperhost and action per service type
      ret.result_types.values.each do |result_type|
        # binding.pry
        result_type.produce
      end
      ret.service_instances.values.each do |service_instance|
        service_instance.produce
      end
      # now connect
      ret.result_types.values.each do |result_type|
        # binding.pry if result_type.kind_of?(Construqt::Flavour::Nixian::Services::IpsecOncePerHost)
        result_type.service_instances.each do |si|
          result_type.attach_service(si)
          si.attach_result(result_type.instance)
        end
        result_type.factory.machine.attach_types.each do |at|
          ret.service_types[at.name].result_types.each do |ins|
            # binding.pry
            result_type.attach_result(ins.instance)
          end
        end
      end
      ret
    end
  end

  class HostsServicesResult
    attr_reader :hosts
    def initialize
      @hosts = {}
    end
    def attach_from_hosts(hosts)
      ret = HostsServicesResult.new
      hosts.each do |host|
        @hosts[host] ||= ResultTypes.produce(host)
        host.attach_result_types(@hosts[host])
      end
      ret
    end
    def fire_host_interface(host, iface, action)
    end
    def fire_host(host, action)
      result_types = @hosts[host]
      throw "hostname found: #{host.name}" unless result_types
      # binding.pry
      # fire to service_instances
      result_types.service_instances.values.each do |i|
        i.instance.respond_to?(action) and i.instance.send(action)
      end
      # fire to result_type_instances
      result_types.result_types.values.each do |i|
        i.instance.respond_to?(action) and i.instance.send(action)
      end
    end

    def fire(action)
      @hosts.keys.each do |host|
        fire_host(host, action)
      end
    end
  end

end
