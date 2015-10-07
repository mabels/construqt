require_relative("ciscian/deploy_template")

module Construqt
  module Flavour
    class Ciscian

      class Factory
        def name
          'ciscian'
        end
        def factory(cfg)
          FlavourDelegate.new(Ciscian.new)
        end
      end

      Construqt::Flavour.add(Factory.new)

      @dialects={}
      def self.dialects
        @dialects
      end

      def self.add_dialect(dialect)
        @dialects[dialect.name] = dialect
      end

      class Result
        attr_accessor :dialect,:host, :sections
        def initialize(host)
          @host = host
          @sections = {}
          throw "ciscian flavour can only be created with dialect" unless host.dialect
          require_relative "ciscian/dialect_#{host.dialect}.rb"
          throw "cannot load dialect class #{host.dialect}" unless Ciscian.dialects[host.dialect]
          self.dialect=Ciscian.dialects[host.dialect].new(self)
        end

        class Lines
          class Line
            attr_reader :to_s, :nr
            def initialize(str, nr)
              @to_s = str
              @nr = nr
            end
          end

          def initialize(lines)
            @lines = []
            lines.each_with_index do |line, idx|
              @lines << Line.new(line.strip, idx)
            end

            @pos = 0
          end

          def shift
            @pos += 1
            @lines[@pos-1]
          end
        end

        def parse(lines)
          lines = Lines.new(lines)
          while line = lines.shift
            parse_line(line, lines, self, self)
          end

          self
        end

        def self.normalize_section_key(key)
          matchdata=key.match(/^\s*(no\s+|)(.*)/)
          matchdata[2]
        end

        def self.starts_with_no(key)
          return key.match(/^\s*no\s+/)
        end

        def parse_line(line, lines, section, result)
          return if self.dialect.parse_line(line, lines, section, result)
          [NestedSection, SingleValueVerb].find do |clazz|
            clazz.parse_line(line, lines, section, result)
          end
        end

        def serialize
          block=[]
          section_keys = self.dialect.sort_section_keys(@sections.keys)
          section_keys.each do |key|
            section = @sections[key]
            block += section.serialize
          end
          block
        end

        def commit
          self.dialect.commit
          Util.write_str(self.serialize().join("\n"), File.join(@host.name, "#{@host.fname||self.dialect.class.name}.cfg"))
          external=@host.id.interfaces.first.address
          #external_ip=external.first_ipv4.nil? ? external.first_ipv6.to_s : external.first_ipv4.to_s
          external_ip=@host.name
          DeployTemplate.write_template(@host, self.dialect.class.name, external_ip, "root", @host.password||@host.region.hosts.default_password)
        end

        def add(section, clazz=SingleValueVerb)
          throw "section is nil" unless section
          section = Lines::Line.new(section, -1) unless section.kind_of?(Lines::Line)
          section_key=Result.normalize_section_key(section.to_s)

          @sections[section_key] ||= clazz.new(section_key)
          if Result.starts_with_no(section.to_s)
            @sections[section_key].no
          else
            @sections[section_key].yes
          end

          yield(@sections[section_key]) if block_given?
          @sections[section_key]
        end

        def self.compare(nu, old)
          result = Result.new(nu.host)

          nu_root=NestedSection.new("root")
          nu_root.sections.merge!(nu.sections)
          other_root=NestedSection.new("root")
          other_root.sections.merge!(old.sections)

          deltas=NestedSection.compare(nu_root, other_root)
          throw "illegal state" if deltas.length != 1
          result.sections = deltas[0].sections unless deltas[0].nil?
          result
        end
      end

      class SingleValueVerb
        attr_accessor :section,:value
        def initialize(section)
          self.section=section
        end

        def serialize
          val = @quotes ? "\"#{value}\"" : value
          [[@no, section , val].compact.join(" ")]
        end

        def self.compare(nu, old)
          return [nu] unless old
          # return no changes (empty list) if old configuration of single value verb (default) is not explicitly reconfigured in new configuration:
          return [] unless nu
          return [nu] unless nu.serialize == old.serialize
          [nil]
        end

        def add(value)
          self.value=value
          self
        end

        def no
          @no="no"
          self.value=nil
          self
        end

        def yes
          @no=nil
          self
        end

        def quotes
          @quotes=true
          self
        end

        def self.parse_line(line, lines, section, result)
          quotes = line.to_s.strip.end_with?("\"")
          regexp = quotes ? /^\s*((no|).*) \"([^"]+)\"$/ : /^\s*((no|).*) ([^\s"]+)$/
          if (line.to_s.strip =~ regexp)
            key=$1
            val=$3
            sec = section.add(key, Ciscian::SingleValueVerb).add(val)
            sec.quotes if quotes
          else
            section.add(line.to_s, Ciscian::SingleValueVerb)
          end
        end
      end

      class NestedSection
        attr_accessor :section,:sections
        def initialize(section)
          self.sections={}
          self.section=section
        end

        def add(verb, clazz = SingleValueVerb)
          section_key=Result.normalize_section_key(verb.to_s)
          self.sections[section_key] ||= clazz.new(section_key)

          if Result.starts_with_no(verb.to_s)
            @sections[section_key].no
          end
          @sections[section_key]
        end

        def self.parse_line(line, lines, section, result)
          if [/^\s*(no\s+|)interface/, /^\s*(no\s+|)vlan/].find{|i| line.to_s.match(i) }
            resultline=Result::Lines::Line.new(result.dialect.clear_interface(line), line.nr)
            section.add(resultline.to_s, NestedSection) do |_section|
              _section.virtual if result.dialect.is_virtual?(resultline.to_s)
              while _line = lines.shift
                break if result.dialect.block_end?(_line.to_s)
                result.parse_line(_line, lines, _section, result)
              end
            end

            if (matchdata = line.to_s.match(Construqt::Util::PORTS_DEF_REGEXP))
              ports = Construqt::Util::expandRangeDefinition(matchdata[0])
              if (ports.length>1)
                section_to_split=section.sections.delete(resultline.to_s)
                ports.each do |port|
                  section.add(line.to_s.gsub(/#{Construqt::Util::PORTS_DEF_REGEXP}/, port), NestedSection) do |_section|
                    _section.sections.merge!(section_to_split.sections)
                  end
                end
              end
            end

            return true
          end
        end

        def render_verbs(verbs)
          block=[]
          sections.keys.sort.each do |key|
            verb = sections[key]
            block << verb.serialize.map{|i| "  #{i}"}
          end

          block
        end

        def no
          @no="no "
          @sections={}
          self
        end

        def no?
          @no
        end

        def yes
          @no=nil
          self
        end

        def virtual
          @virtual=true
          self
        end

        def serialize
          block=[]
          if (!self.sections.empty? || (self.sections.empty? && @virtual) || (@no && @virtual))
            block << "#{@no}#{section.to_s}"
            unless (@no)
              block += render_verbs(self.sections)
              block << "exit"
            end
          end

          block
        end

        def self.compare(nu, old)
          return [nu] unless old
          return [old.no] unless nu
          throw "classes must match #{nu.class.name} != #{old.class.name}" unless nu.class == old.class

          if (nu.serialize==old.serialize)
            return [nil]
          else
            if (nu.no?)
              return [nu]
            else
              delta = nu.class.new(nu.section)
              (nu.sections.keys + old.sections.keys).uniq.sort.each do |k,v|
                nu_section=nu.sections[k]
                old_section=old.sections[k]
                comps = (nu_section||old_section).class.compare(nu_section, old_section)
                throw "class #{(nu_section||old_section).class.name} returns illegal nil in compare method" unless comps
                comps.compact.each do |comp|
                  delta.sections[comp.section] = comp
                end
              end

              return [delta]
            end
          end
        end
      end

      class RangeVerb
        attr_accessor :section,:values
        def initialize(section)
          self.section=section
          self.values = []
        end

        def add(value)
          #throw "must be a number \'#{value}\'" unless /^\d+$/.match(value.to_s)
          self.values << value #.to_i
          self
        end

        def no
          @no="no "
          self
        end

        def yes
          @no=nil
          self
        end

        def self.compare(nu, old)
          return [nu] unless old
          return [old.no] unless nu
          throw "classes must match #{nu.class.name} != #{old.class.name}" unless nu.class == old.class
          if (nu.serialize==old.serialize)
            [nil]
          else
            [nu]
          end
        end

        def serialize
          if @no
            ["#{@no}#{section} #{Construqt::Util.createRangeDefinition(values)}"]
          else
            ["#{section} #{Construqt::Util.createRangeDefinition(values)}"]
          end
        end
      end

      class PatternBasedVerb
        attr_accessor :section, :changes

        def initialize(section)
          self.section=section
          self.changes=[]
        end

        def yes
        end

        def add(entry)
          changes << entry
          self
        end

        def self.invert(a)
          return a.gsub(/\+/,"-") if a.match(/\+/)
          return a.gsub(/\-/,"+") if a.match(/\-/)
          throw "cannot invert #{a}"
        end

        def self.variables(patterns)
          variables=[]
          patterns.each do |pattern|
            variables+=find_variables(pattern)
          end

          return variables
        end

        def self.find_variables(pattern)
          return pattern.scan(/{[^}]+}/)
        end

        def self.parse_line(line, lines, section, result)
          entry=matches(self.patterns, line.to_s)
          return false unless entry
          section.add(self.section, self).add(entry)
          return true
        end

        def self.find_regex(varname)
          return nil
        end

        def self.extract_varname(variable)
          matchdata=variable.match(/{(\+|\-|\=|\*)([^}]+)}/)
          throw "could not extract varname from #{variable}" unless matchdata
          return matchdata[2]
        end

        def self.matches(patterns, line)
          patterns.each do |pattern|
            variables = find_variables(pattern)
            regex=pattern
            variables.each do |var|
              var_regex = find_regex(extract_varname(var))
              var_regex = "#{Construqt::Util::PORTS_DEF_REGEXP}" unless var_regex
              regex=regex.gsub(var, var_regex)
            end

            regex=regex.gsub(" ", "\\s+")
            regex="^"+regex+"$"
            if (matchdata=line.match(regex))
              values={"pattern" => pattern}
              (1..variables.length).each do |i|
                if find_regex(extract_varname(variables[i-1])).nil?
                  values[variables[i-1]]=Construqt::Util.expandRangeDefinition(matchdata[i])
                else
                  values[variables[i-1]]=[matchdata[i]]
                end
              end

              return values
            end
          end

          return false
        end

        def self.compare(nu, old)
          unless (nu.nil? || old.nil?)
            if (nu.serialize==old.serialize)
              return []
            end
          end

          nu_ports=nu.nil? ? {} : nu.integrate
          old_ports=old.nil? ? {} : old.integrate

          result = self.new(self.section)

          key_var = (old||nu).find_key_var
          set_keys = (old||nu).keys_of_set + (nu||old).keys_of_set

          set_keys.each do |key_val|
            variables(self.patterns).each do |v|
              if is_key_value?(v)
                result.add({key_var => key_val})
              elsif is_value?(v)
                result.add({key_var => key_val, v => (nu_ports[key_val] && nu_ports[key_val][v]) ? nu_ports[key_val][v] : nil})
              else
                set = []
                set += nu_ports[key_val][v] if nu_ports[key_val]
                set += old_ports[key_val][invert(v)] if old_ports[key_val] && old_ports[key_val][invert(v)]
                set -= nu_ports[key_val][invert(v)] if nu_ports[key_val] && nu_ports[key_val][invert(v)]
                set -= old_ports[key_val][v] if old_ports[key_val]
                result.add({key_var => key_val, v => set}) if set.length > 0
              end
            end
          end

          return [result]
        end

        def self.is_key_value?(v)
          return !v.nil? && v.start_with?("{*")
        end

        def self.is_value?(v)
          return !v.nil? && v.start_with?("{=")
        end

        def find_key_var
          #find variable for key
          key_var=nil
          changes.each do |entry|
            entry.keys.each do |v|
              if self.class.is_key_value?(v)
                throw "can only have one key value variable in pattern {*var}" if key_var !=nil && key_var !=v
                key_var = v
              end
            end
          end

          return key_var
        end

        def keys_of_set
          keys=[]

          key_var=find_key_var

          if key_var
            changes.each do |entry|
              keys << entry[key_var] if entry[key_var]
            end
          end

          return keys unless keys.empty?
          return [nil]
        end

        def integrate
          set_keys = keys_of_set

          #initialize sets
          sets={}
          set_keys.each do |key_val|
            sets[key_val] = {}
          end

          #initialize start values of values inside sets
          set_keys.each do |key_val|
            self.class.variables(self.class.patterns).each do |v|
              if self.class.is_key_value?(v)
                sets[key_val][v]=key_val
              elsif self.class.is_value?(v)
                sets[key_val][v]=nil
              else
                sets[key_val][v]=[]
              end
            end
          end

          key_var=find_key_var
          changes.each do |entry|
            sets.each do|key_val,value_sets|
              value_sets.each do |v,set|
                if (entry[key_var]==key_val)
                  if self.class.is_key_value?(v)
                    value_sets[v] = entry[v]
                  elsif self.class.is_value?(v)
                    value_sets[v] = entry[v]
                  else
                    value_sets[v] += entry[v] if entry[v]
                    #remove duplicates without changing insertion order:
                    value_sets[v] = value_sets[v].reverse.uniq.reverse

                    value_sets[self.class.invert(v)] -= entry[v] if entry[v] && value_sets[self.class.invert(v)]
                  end
                end
              end
            end
          end

          return sets
        end

        def always_select_empty_pattern
          false
        end

        def determine_output_patterns(value_sets)
          output_patterns=[]
          empty_pattern = nil
          self.class.patterns.each do |pattern|
            pvs = self.class.find_variables(pattern)
            if (pvs.empty?)
              empty_pattern=pattern
            else
              pvs.each do |pv|
                if (!value_sets[pv].nil? && !value_sets[pv].empty?)
                  output_patterns << pattern
                  break
                end
              end
            end
          end

          output_patterns.unshift(empty_pattern) if (output_patterns.empty? || self.always_select_empty_pattern) && !empty_pattern.nil?
          return output_patterns
        end

        def group?
          true
        end

        def prefer_no_verbs?
          false
        end

        def prefer_no_verbs_sort(buffer)
          return buffer.sort do |a,b|
            ret=0
            ret = Construqt::Util.rate_higher("no ",a, b) if ret==0
            ret = a<=>b if ret==0
            ret
          end
        end

        def serialize
          buffer = []
          sets = integrate

          sets.each do |key_val,value_sets|
            determine_output_patterns(value_sets).each do |pattern|
              index = 0
              i = 0
              begin
                substitution=false
                result = pattern
                i += 1
                self.class.find_variables(pattern).each do |v|
                  if (self.group?)
                    if (!value_sets[v].kind_of?(Array) && (self.class.is_value?(v) || self.class.is_key_value?(v)))
                      result = result.gsub(v, value_sets[v].to_s) unless value_sets[v].nil? || value_sets[v].to_s.empty?
                    else
                      result = result.gsub(v, Construqt::Util.createRangeDefinition(value_sets[v])) unless value_sets[v].nil? || value_sets[v].empty?
                    end
                  else
                    if (index < value_sets[v].length)
                      result = result.gsub(v, value_sets[v][index])
                      substitution=true
                    end
                  end
                end

                buffer << result if self.class.find_variables(result).empty?
                index+=1
              end while substitution
            end
          end

          buffer = prefer_no_verbs_sort(buffer) if prefer_no_verbs?

          return buffer
        end
      end

      class Host < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def header(host)
          "# this is a generated file do not edit!!!!!"
        end

        def footer(host)
          "# this is a generated file do not edit!!!!!"
        end

        def build_config(host, unused)
          host.result.dialect.add_host(host)
        end
      end

      class Device  < OpenStruct
        include Construqt::Cables::Plugin::Single
        def initialize(cfg)
          super(cfg)
        end

        def self.header(path)
          "# this is a generated file do not edit!!!!!"
        end

        def build_config(host, device)
          host.result.dialect.add_device(device)
        end
      end

      class Vlan < OpenStruct
        include Construqt::Cables::Plugin::Single
        def initialize(cfg)
          super(cfg)
        end

        def self.header(path)
          "# this is a generated file do not edit!!!!!"
        end

        def build_config(host, device)
          host.result.dialect.add_vlan(device)
        end
      end

      class Bond  < OpenStruct
        include Construqt::Cables::Plugin::Single
        def initialize(cfg)
          super(cfg)
        end

        def self.header(path)
          "# this is a generated file do not edit!!!!!"
        end

        def build_config(host, bond)
          host.result.dialect.add_bond(bond)
        end
      end

      class NotImplemented < OpenStruct
        def initialize(cfg)
          super(cfg)
        end

        def self.header(path)
          "# this is a generated file do not edit!!!!!"
        end

        def build_config(host, iface)
          throw "not implemented on this flavour #{iface.class.name}"
        end
      end

      def clazzes
        {
          "opvn" => NotImplemented,
          "bond" => Bond,
          "bridge" => NotImplemented,
          "gre" => NotImplemented,
          "vrrp" => NotImplemented,
          "template" => NotImplemented,
          "vlan" => Vlan,
          "host" => Host,
          "device"=> Device,
          "result" => Result
        }
      end

      def clazz(name)
        ret = self.clazzes[name]
        throw "class not found #{name}" unless ret
        ret
      end

      def create_host(name, cfg)
        cfg['name'] = name
        cfg['result'] = nil
        host = Host.new(cfg)
        host.result = Result.new(host)
        host
      end

      def create_interface(name, cfg)
        cfg['name'] = name
        clazz(cfg['clazz']).new(cfg)
        #cfg['name'] = name
        #Interface.new(cfg)
      end
    end
  end
end
