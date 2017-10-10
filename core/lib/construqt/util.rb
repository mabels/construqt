require 'zlib'
require 'erb'
require 'shellwords'
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

    def self.sh_escape(*str)
      str.map{|s| Shellwords.escape(s) }.join(" ")
    end

    def self.dst_path(region)
      region.get_dest_path || "cfgs"
    end

    def self.read_str(region, *path)
      path = File.join(dst_path(region), *path)
      IO.read(path)
    end

    def self.read_str!(region, *path)
      path = File.join(dst_path(region), *path)
      File.exists?(path) && IO.read(path)
    end

    def self.write_gzip(region, str, *path)
      path = File.join(dst_path(region), '.zipped', *path)+".gz"
      FileUtils.mkdir_p(File.dirname(path))
      Zlib::GzipWriter.open(path) do |gz|
          gz.write str
      end
      path
    end

    def self.output(path)
      @slash_pos ||= 0
      @last_path_length ||= 0
      @dots_str ||= "........"
      @slash_pos = @slash_pos % @dots_str.length
      dots = "[#{@dots_str[0..@slash_pos]}#{@slash_pos%2 == 0 ? "/" : "\\"}#{@dots_str[@slash_pos..-1]}] => "
      out = "#{dots}#{path}"
      ret = ""
      if @last_path_length > out.length
        rest = Array.new(@last_path_length-out.length, " ").join("")
      end
      print "#{out}#{rest}\r"
      @slash_pos += 1
      @last_path_length = out.length
    end

    def self.write_str(region, str, *path)
      path = File.join(dst_path(region), *path)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') {|f| f.write(str) }
      # Construqt.logger.info "Write:#{path}"
      output(path)
      return str
    end

    def self.get_filename(region, *path)
      File.join(dst_path(region), *path)
    end

    def self.open_file(region, *path, &block)
      path = File.join(dst_path(region), *path)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') {|f| block.call(f) }
      Construqt.logger.info "Open:#{path}"
      return path
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

    def self.build_network_address_lookup_table(ips)
      result = {}
      ips.each do |ip|
        (ip.prefix.to_i..(ip.ipv4? ? 32 : 128)).each do |i|
          net = IPAddress.parse("#{ip.to_s}/#{i}").network
          result[net.to_string] = net
        end
      end
      result
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

    def self.space_behind(str)
      if str.nil? or str.empty?
        ""
      else
        str.strip+" "
      end
    end


    def self.snake_case(str)
      str.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end

    def self.camel_case(str)
      return self if self !~ /_/ && self =~ /[A-Z]+.*/
      split('_').map{|e| e.capitalize}.join
    end

    def self.get_directories(ns)
      if ns.nil? || ns.empty?
        raise "There must be a DIRECTORY const defined!"
      end
      m_name = (ns+["DIRECTORY"]).join("::")
      begin
        ret = Object.const_get(m_name)
        if ret.kind_of?(Array)
          ret
        else
          [ret]
        end
      rescue NameError => e
        ns.pop
        get_directories(ns)
      end
    end

    TEMPLATE_CACHE = {}

    def self.template_directories(context)
      name = (context.kind_of?(Module) && context.name) || context.class.name
      directories = get_directories(name.split("::"))
    end

    def self.read_template(context, fname, directories)
      # this is very ruby related, not nice but
      # how to do it better?
      directories.each do |directory|
        fnames = Dir.glob(File.join(directory, "**", fname))
        raise "ambiguous files #{fnames.join(" ")}" if fnames.size > 1
        if fnames.size > 0 && File.exists?(fnames.first)
          return IO.read(fnames.first)
        end
      end
      raise "File not found #{fname} in #{directories.join(",")}"
    end

    def self.render(_binding, fname)
      context = _binding.eval("self")
      directories = template_directories(context)
      template = TEMPLATE_CACHE[(directories+[fname]).join(":")] ||= read_template(context, fname, directories)
      begin
        ERB.new(template, nil, '-').result(_binding)
      rescue Exception => e
        #e.message = "in file #{fname}:[#{e.message}]"
        raise $!, "in file #{fname}:[#{e.message}]", $!.backtrace
      end
    end

    def self.short_ifname(iface)
      return iface.name if iface.name.length < 12
      throw "shortname not buildable #{iface.class.name} #{iface.name}" unless iface.respond_to?(:shortname)
      prefix, ident = iface.shortname
      digest = Base64.encode64(OpenSSL::Digest::SHA256.new(ident).to_s)
      "#{prefix}#{digest[0,12 - prefix.length]}"
    end
  end
end
