module Construct
module Util
  module Chainable
    class Attr
      def initialize
      end
    end
    def self.chainable_attr_value(arg, init = nil)
      instance_variable_name = "@#{arg}".to_sym
      self.instance_variable_set(instance_variable_name, init)
      define_method(arg.to_s) do |val|
        self.instance_variable_set(instance_variable_name, val)
        self  
      end
      define_method("get_#{arg}") do
        self.instance_variable_get(instance_variable_name.to_sym)
      end
    end

    def self.chainable_attr(other, arg, set_value = true, init = false, aspect = lambda{|i|})
      instance_variable_name = "@#{arg}".to_sym
#      puts ">>>chainable_attr #{"%x"%self.object_id} init=#{init}"
#      self.instance_variable_set(instance_variable_name, init)
      puts "self.chainable_attr #{other.name} #{arg.to_sym} #{set_value} #{init}"
      define_method(arg.to_sym) do |*args|
        instance_eval(&aspect)
        self.instance_variable_set(instance_variable_name, args.length>0 ? args[0] : set_value)
        self  
      end
      if ((set_value.kind_of?(true.class) || set_value.kind_of?(false.class)) &&
          (init.kind_of?(true.class) || init.kind_of?(false.class)))
        get_name = "#{arg}?"
      else
        get_name = "get_#{arg}"
      end
      get_name_proc = Proc.new do
        unless self.instance_variables.include?(instance_variable_name)
#puts "init #{get_name} #{instance_variable_name} #{defined?(instance_variable_name)} #{set_value} #{init}"
          self.instance_variable_set(instance_variable_name, init)
        end
        ret = self.instance_variable_get(instance_variable_name)
puts "#{self.class.name} #{get_name} #{set_value} #{init} => #{ret.inspect}"
        ret
      end
      define_method(get_name, get_name_proc)
    end
    class Test
      include Chainable
      #def initialize
      #  puts ">>>test instance=#{"%x"%self.object_id} class=#{"%x"%self.class.object_id}"
      #end
      attr_reader :sideeffect
      chainable_attr :bloed0
      chainable_attr :bloed1
      chainable_attr :test, 1, 2
      chainable_attr :testbool, false, true
      chainable_attr :testbool2, true, true
      chainable_attr :testside, 1, 2, lambda {|i| @sideeffect ||= 9; @sideeffect += 1 }

        chainable_attr :interface
        chainable_attr :connection
        chainable_attr :input_only, true, true
        chainable_attr :output_only, true, true
        chainable_attr :connection
        chainable_attr_value :log, nil
        chainable_attr_value :from_net, nil
        chainable_attr_value :to_net, nil
        chainable_attr_value :action, nil
    end
    def self.test
      3.times do |i|
        t = Test.new
        throw "chainable failed input_only" unless t.input_only? == true
        throw "chainable failed output_only" unless t.output_only? == true

        puts "#{i}=>#{t.testbool?} #{t.testbool2?}"
        throw "chainable failed test should 2 #{t.get_test.inspect}" if t.get_test != 2
        t.test
        throw "chainable failed this should be 1 " if t.get_test != 1
        t.test(3)
        throw "chainable failed" if t.get_test != 3

        throw "chainable failed test should 2 #{t.get_testside.inspect}" if t.get_testside != 2
        throw "chainable failed sideeffect should 1 nil #{t.sideeffect.inspect}" if !t.sideeffect.nil?
        t.testside
        throw "chainable failed this should be 1 " if t.get_testside != 1
        throw "chainable failed sideeffect should 2 nil #{t.sideeffect.inspect}" if t.sideeffect != 10
        t.testside(3)
        throw "chainable failed" if t.get_testside != 3
        throw "chainable failed sideeffect should 2 nil #{t.sideeffect.inspect}" if t.sideeffect != 11

        throw "chainable failed true" unless t.testbool? == true
        t.testbool
        throw "chainable failed false" unless t.testbool? == false
        t.testbool(4)
        throw "chainable failed 4" unless t.testbool? == 4
        t.testbool
        throw "chainable failed false" unless t.testbool? == false

        throw "chainable failed 2 true" unless t.testbool2? == true
        t.testbool2
        throw "chainable failed 2 false" unless t.testbool2? == true
        t.testbool2(4)
        throw "chainable failed 2 4" unless t.testbool2? == 4
        t.testbool2
        throw "chainable failed 2 false" unless t.testbool2? == true
      end
      a=[Test.new,Test.new,Test.new]
      a[0].testbool(0)
      throw "chainable failed 0" unless a[0].testbool? == 0
      throw "chainable failed 1" unless a[1].testbool? == true
      a[2].testbool
      throw "chainable failed 2" unless a[2].testbool? == false

      throw "chainable failed 0" unless a[0].testbool? == 0
      throw "chainable failed 1" unless a[1].testbool? == true
      throw "chainable failed 2" unless a[2].testbool? == false
    end
    @test = self.test
  end

  def self.write_str(str, *path)
    path = File.join("cfgs", *path)
    FileUtils.mkdir_p(File.dirname(path))
    File.open(path, 'w') {|f| f.write(str) }
    Construct.logger.info "Write:#{path}"
    return str
  end
   def self.password(a)
      a
   end
   def self.add_gre_prefix(name)
      unless name.start_with?("gt")
         return "gt"+name
      end
      name
   end
   @clean_if = []
   def self.add_clean_ip_pattern(pat)
     @clean_if << pat
   end
   def self.clean_if(prefix, name)
     unless name.start_with?(prefix)
       name = prefix+name
     end
     name = name.gsub(/[^a-z0-9]/, '')
     @clean_if.each { |pat| name.gsub!(pat, '') }
     name
   end
   def self.clean_bgp(name)
     name.gsub(/[^a-z0-9]/, '_')
   end
end
end
