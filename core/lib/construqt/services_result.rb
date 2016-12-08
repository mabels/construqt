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
    attr_reader :key, :result_types, :service_producers, :in_links, :out_links
    def initialize(key)
      @key = key
      @result_types = Set.new
      @service_producers = Set.new
      @out_links = Set.new
      @in_links = Set.new
    end
    def inspect
     "#<#{self.class.name}:#{self.object_id} "+
     "key=#{key} "+
     "result_types=#{@result_types.map{|i| i.inspect }} "+
     "service_producers=#{@service_producers.map{|i| i.inspect }} "+
     "out_links=#{@out_links.map{|i| i.key }} "+
     "in_links=#{@in_links.map{|i| i.key }} "+
     ">"
    end
    def add_service_producer(srv_prod)
      @service_producers.add(srv_prod)
    end
    def add_result_types(rtypes)
      rtypes.each do |rt|
        @result_types.add(rt)
      end
    end
    def join(other)
      throw "other has to be service_type" unless other.kind_of?(self.class)
      # binding.pry if other.in_links.find{|i| i == self}
      throw "cyclic #{self.inspect} #{other.inspect}" if other.in_links.include?(self)
      other.out_links.add(self)
      self.in_links.add(other)
    end
    def dependcy_list(visited)
      ret = []
      return [] if visited.include?(self.object_id)
      # puts "Key=#{self.key}#{"%x"%self.object_id} #{visited.to_a.join(":")}"
      # binding.pry
      self.in_links.each do |o|
        ret += o.dependcy_list(visited)
      end
      # puts "VisitKey=#{self.key}#{"%x"%self.object_id}"
      visited.add(self.object_id)
      ret.push self
      ret
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
      @activated = nil
    end
    def produce
      @instance = factory.produce(host, srv_inst, self)
    end

    def activate(rt)
      unless @activated
        throw "activate failed no instance" unless @instance
        @instance.respond_to?(:activate) and @instance.activate(rt)
        @activated = rt
      else
        throw "rt is not the same" if @activated != rt
      end
    end

    # def attach_result(res)
    #   throw "attach_result failed no instance" unless @instance
    #   @instance.respond_to?(:attach_result) and @instance.attach_result(res)
    # end
  end

  class ResultTypeProducer
    attr_reader :result_type, :factory, :host, :iface, :instance, :service_instances
    def initialize(result_type, factory, host, iface)
      @result_type = result_type
      @factory = factory
      @host = host
      @iface = iface
      @service_instances = Set.new
      @activated = nil
    end
    def produce
      # binding.pry
      unless @instance
        @instance = result_type.new
        @instance.respond_to?(:attach_host) && @instance.attach_host(host)
        @instance.respond_to?(:attach_interface) && @instance.attach_interface(iface)
      end
      @instance
    end
    def activate(rt)
      unless @activated
        throw "activate failed no instance" unless @instance
        @instance.respond_to?(:activate) and @instance.activate(rt)
        @activated = rt
      else
        throw "rt is not the same" if @activated != rt
      end
    end
    # def attach_service(si)
    #   throw "attach_service failed no instance" unless @instance
    #   @instance.respond_to?(:attach_service) and @instance.attach_service(si)
    # end
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
        binding.pry if rt ==  Construqt::Flavour::Nixian::Services::Result::Service
        @result_types[rt] ||= ResultTypeProducer.new(rt, factory, host, iface)
        @result_types[rt].add_service_producer(srv_prod)
        @result_types[rt]
      end
    end

   def add(srv_inst, factory, host, iface = nil)
     srv_prod = add_service_instance(srv_inst, factory, host, iface)
     result_types = add_result_type(srv_prod, factory, host, iface)
     @service_types[srv_inst.class.name] ||= ServiceType.new(srv_inst.class.name)
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

    def find_instances_from_type(type)
      ret = @result_types[type]
      throw "type not found #{type}" unless ret
      ret.instance
    end

    #def self.attach_service(ref, srv_inst, ret)
    #  return unless impl.respond_to?(:result_type)
    #  ret.add_result_type(impl.result_type, srv_inst)
    #end
    def create_dependency_graph
      service_types.map do |key, i|
        i.service_producers.map do |j|
          j.factory.machine.depends.each do |k|
            binding.pry unless service_types[k.name]
            service_types[k.name].join(i)
          end
          j.factory.machine.requires.each do |k|
            binding.pry unless service_types[k.name]
            i.join(service_types[k.name])
          end
        end
      end
    end
    def service_construction_order
      out = []
      visited = Set.new
      service_types.map do |key, v|
        out += v.dependcy_list(visited)
      end
      out.reverse!
      # binding.pry if @host.name == "dns-1"
      out
    end


    def run_construction_order(rt_lambda, sp_lambda)
      sdo = self.service_construction_order
      # create all instances onceperhost and action per service type
      sdo.each do |service_instance|
        service_instance.result_types.each do |rt|
          rt_lambda.call(rt)
        end
        service_instance.service_producers.each do |sp|
          sp_lambda.call(sp)
        end
      end
    end

    def run_deconstruction_order(rt_lambda, sp_lambda)
      sdo = self.service_construction_order.reverse
      # create all instances onceperhost and action per service type
      sdo.each do |service_instance|
        service_instance.service_producers.each do |sp|
          sp_lambda.call(sp)
        end
        service_instance.result_types.each do |rt|
          rt_lambda.call(rt)
        end
      end
    end


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
      # sort by dependcy
      ret.create_dependency_graph
      # create all instances onceperhost and action per service type
      ret.run_construction_order(lambda{|rt| rt.produce }, lambda{|sp| sp.produce})
      # in our machines there are some activators
      activators = {}
      ret.service_types.each do |st_type, st|
        # binding.pry
        st.service_producers.each do |sp|
          sp.factory.machine.activators.each do |key, as|
            activators[key] ||= []
            activators[key] += as
          end
        end
      end
      prog_rt_activators = lambda do |rt|
        (activators[rt.instance.class]||[]).each do |ac|
          ac.call(rt.instance)
        end
      end

      prog_st_activators = lambda do |st|
        # binding.pry
        (activators[st.srv_inst.class]||[]).each do |ac|
          ac.call(st.srv_inst)
        end
      end

      ret.run_construction_order(prog_rt_activators, prog_st_activators)
      # binding.pry unless activators.empty?
      #ret.result_type.values.first.service_producers.first.factory.machine
      # now connect
      ret.run_construction_order(lambda{|rt| rt.activate(ret) }, lambda{|sp| sp.activate(ret)})
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
    def fire_host_interface_construction_order(host, iface, action)
      result_types = @hosts[host]
      throw "hostname found: #{host.name}" unless result_types

      result_actor = lambda { |i| i.instance.respond_to?(action) and i.instance.send(action, iface) }
      service_actor = lambda do |i|
        if i.instance.respond_to?(action) and iface == i.iface
          # binding.pry if host.name == "fanout-de" and iface.name == "eth0"
          i.instance.send(action, iface)
        end
      end
      result_types.run_construction_order(result_actor, service_actor)
    end
    def fire_host_construction_order(host, action)
      result_types = @hosts[host]
      throw "hostname found: #{host.name}" unless result_types
      actor = lambda { |i| i.instance.respond_to?(action) and i.instance.send(action) }
      result_types.run_construction_order(actor, actor)
    end

    def fire_host_destruction_order(host, action)
      result_types = @hosts[host]
      throw "hostname found: #{host.name}" unless result_types
      actor = lambda { |i| i.instance.respond_to?(action) and i.instance.send(action) }
      result_types.run_deconstruction_order(actor, actor)
    end


    def fire_construction_order(action)
      @hosts.keys.each do |host|
        fire_host_construction_order(host, action)
      end
    end
  end

end
