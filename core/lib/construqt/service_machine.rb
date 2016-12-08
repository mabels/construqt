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
      "activator=[#{@activators.keys.map{|i|i.name}.join(",")}] "+
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
end
