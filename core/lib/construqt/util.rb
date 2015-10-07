require 'zlib'
module Construqt
  module Util
    module Chainable

      def self.included(other)
        #puts "Chainable #{other.name}"
        other.class.send("define_method", "chainable_attr") do |*args|
          #puts "chainable_attr:#{self.name} #{args.inspect}"
          Chainable.chainable_attr(self, *args)
        end

        other.class.send("define_method", "chainable_attr_value") do |*args|
          #puts "chainable_attr_value:#{self.name} #{args.inspect}"
          Chainable.chainable_attr_value(self, *args)
        end
      end

      def self.chainable_attr_value(clazz, arg, init = nil)
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

      def self.chainable_attr(clazz, arg, set_value = true, init = false, aspect = lambda{|i|})
        instance_variable_name = "@#{arg}".to_sym
        #      puts ">>>chainable_attr #{"%x"%self.object_id} init=#{init}"
        #      self.instance_variable_set(instance_variable_name, init)
        #puts "self.chainable_attr #{clazz.name} #{arg.to_sym} #{set_value} #{init}"
        clazz.send("define_method", arg.to_sym) do |*args|
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
          #puts "#{self.class.name} #{get_name} #{set_value} #{init} => #{ret.inspect}"
          ret
        end

        clazz.send("define_method", get_name, get_name_proc)
      end
    end

    def self.read_str(*path)
      path = File.join("cfgs", *path)
      IO.read(path)
    end

    def self.write_gzip(str, *path)
      path = File.join("cfgs", *path)+".gz"
      FileUtils.mkdir_p(File.dirname(path))
      Zlib::GzipWriter.open(path) do |gz|
          gz.write str
      end
      path
    end

    def self.write_str(str, *path)
      path = File.join("cfgs", *path)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') {|f| f.write(str) }
      Construqt.logger.info "Write:#{path}"
      return str
    end

    def self.get_serial_from_git
      `git log --pretty=format:'%at' -1`.strip.chomp
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

    def self.portNeighbors?(port1, port2)
      port2.succ == port1 || port1.succ == port2
    end

    def self.createRangeDefinition(ports)
      ranges=[]
      lastPort=nil

      #remove duplicates
      ports.uniq.sort do |l,r|
        fc = l.to_s.length <=> r.to_s.length
        fc!=0 ? fc : l<=>r
      end.each do |port|
        port = port.to_s
        if  (ranges.length>0 && portNeighbors?(port, ranges[ranges.length-1]["to"]))
          ranges[ranges.length-1]["to"] = port
        else
          ranges << {"from" => port, "to" => port}
        end
      end

      ranges = ranges.map do |range|
        range["from"] == range["to"] ? range["from"] : range["from"] +"-"+range["to"]
      end

      #puts "self.createRangeDefinition[#{ports}]=>#{ranges}"
      ranges.join(",")
    end

    PORTS_DEF_REGEXP = "((?:[^\\d\\s]*[\\d,-]+)+)"
    PORT_NAME_REGEXP="^(.*?)(\\d+)$"
    def self.expandRangeDefinition(list_str)
      ports = list_str.strip.split(",").map do |range_def|
        range = range_def.split("-")
        if (range.length==1)
          range
        elsif (range.length==2)
          range[0]=~/#{PORT_NAME_REGEXP}/
          prefix_from=$1
          from = $2
          range[1]=~/#{PORT_NAME_REGEXP}/
          prefix_to=$1
          to = $2
          throw "port prefixes differ" unless prefix_from==prefix_to
          (from.to_i .. to.to_i).map {|n| prefix_from + n.to_s }
        else
          throw "invalid range found #{range_def}"
        end
      end

      ports.flatten
    end

    def self.rate_higher(prefix, a, b)
      return a.start_with?(prefix) ^ b.start_with?(prefix) ? (a.start_with?(prefix) ? -1 : 1) : 0
    end

    def self.generate_mac_address_from_name(name)
      # http://www.iana.org/assignments/ethernet-numbers/ethernet-numbers.xhtml
      '8f:'+Digest::SHA256.hexdigest("#{name}").scan(/../)[0,5].join(':')
    end

    def self.indent(body, ident)
      if ident.kind_of?(Fixnum)
        ident = (1..ident).to_a.map{' '}.join('')
      end

      body.lines.map { |line| ident+line.chomp.strip }.join("\n")
    end

    def self.space_before(str)
      if str.nil? or str.empty?
        ""
      else
        " "+str.strip
      end
    end
  end
end
