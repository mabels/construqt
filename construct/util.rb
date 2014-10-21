module Construct
module Util
  module Chainable
    def self.included(clazz)
      puts "++++++++++++++#{clazz.name}"
    end
    def chainable_attr_value(arg, init = nil)
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

    def chainable_attr(arg, default = true, init = false)
      instance_variable_name = "@#{arg}".to_sym
      self.instance_variable_set(instance_variable_name, init)
      define_method(arg.to_s) do |*args|
        self.instance_variable_set(instance_variable_name, default)
        self  
      end
      if ((default.kind_of?(true.class) || default.kind_of?(false.class)) &&
          (init.kind_of?(true.class) || init.kind_of?(false.class)))
        get_name = "#{arg}?"
      else
        get_name = "get_#{arg}"
      end
      define_method(get_name) do
        self.instance_variable_get(instance_variable_name.to_sym)
      end
    end
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
