module Construqt

  class ServiceMachine
    attr_reader :service_types, :result_types, :depends, :requires, :activators
    def initialize(sf)
      @services_factory = sf
      @service_types = []
      @result_types = []
      @depends = []
      @requires = []
      @activators = {}
    end
    def inspect
      "#<#{self.class.name}:#{object_id} "+
      "depends=[#{@depends.map{|i|i.name}.join(",")}] "+
      "activator=[#{@activator.keys.map{|i|i.name}.join(",")}] "+
      "service_types=[#{@service_types.map{|i|i.name}.join(",")}] "+
      "result_types=[#{@result_types.map{|i|i.name}.join(",")}]>"
    end
    def activator(activator)
      activator.actions.each do |type, actor|
        @activators[type] ||= []
        @activators[type].push(actor)
      end
      self
    end
    def service_type(type)
      @service_types.push type
      self
    end
    def result_type(type)
      @result_types.push type
      self
    end
    def depend(type)
      @depends.push type
      self
    end
    def require(type)
      @requires.push type
      self
    end
  end



  class ServicesFactoryShadow
    def initialize(parent)
      throw "parent must be a Services" unless parent.kind_of?(ServicesFactory)
      @parent = parent
      @me = ServicesFactory.new(parent)
    end

    def machine
      @me.machine
    end

    def flavour
      @parent.flavour
    end
    def find(name)
      @me.find!(name) || @parent.find(name)
    end

    def merge(in_srvs, add_missing)
      @me.merge(in_srvs, add_missing)
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

  class ServicesFactory
    attr_reader :flavour#, :services
    def initialize(flavour)
      @flavour = flavour
      @services_factories = { }
    end

    def machine
      ServiceMachine.new(self)
    end

    def shadow
      ServicesFactoryShadow.new(self)
    end

    def find!(name)
      key = name
      key = name.class.name unless name.kind_of?(String)
      key = name.name if key == "Class"
      found = @services_factories[key]
      found ||= @flavour.find!(key)
    end

    def find(name)
      found = find!(name)
      unless found
        binding.pry
        throw "service with name #{name} not found"
      end
      found
    end

    def merge(in_srvs, add_missing)
      srvs = (in_srvs||[]).clone
      to_add_kind_map = add_missing.inject({}){ |r, i| r[i.class.name] = i; r }
      srvs.each do |i|
        to_add_kind_map[i.class.name] &&= nil
      end
      to_add_kind_map.values.each do |i|
        i && srvs.push(i)
      end
      unks = srvs.select do |srv|
        not find!(srv.class.name)
      end
      unless unks.empty?
        throw "unregistered services types #{unks.map{|i| i.class.name}.join(",")}"
      end
      srvs
    end

    # def are_registered_by_instance?(srvs)
      # are_registered_by_name?(srvs.map{|i| i.class.name})
    # end

    def are_registered_by_name?(srvs)
      # puts "#{srvs} #{@services.keys}"
      srvs.empty? || srvs.select{|s| !@services_factories[s] }.empty?
    end

    def each(&block)
      @services_factories.values.each(&block)
    end

    def add(service_factory)
      # binding.pry
      srvs = service_factory.start(self).service_types.map { |sf| sf.name }.sort.uniq
      throw "service names are registered #{srvs}" if are_registered_by_name?(srvs)
      # binding.pry if srvs.first == "BgpStartStop"
      #service_impl.attach_service(self)
      srvs.each do |name|
        @services_factories[name] = service_factory
      end
      self
    end

  end
end
