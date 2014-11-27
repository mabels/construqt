module Construct
  module Flavour
    module Ciscian
      def self.name
        'ciscian'
      end

      Construct::Flavour.add(self)

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
          require("construct/flavour/ciscian/dialect_#{host.dialect}.rb")
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
            def <=>(other)
              a = self.to_s
              b = other.to_s
              match_a=/^(.*[^\d])(\d+)$/.match(a)||[nil,a,1]
              match_b=/^(.*[^\d])(\d+)$/.match(b)||[nil,b,1]
              #puts match_a, match_b, a, b
              ret = match_a[1]<=>match_b[1]
              ret = match_a[2].to_i<=>match_b[2].to_i  if ret==0
              ret
            end
            #            def hash
            #              self.to_s.hash
            #            end
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

        def commit
          self.dialect.commit

          block=[]
          @sections.keys.sort.each do |key|
            section = @sections[key]
            block += section.serialize
          end
          Util.write_str(block.join("\n"), File.join(@host.name, "#{@host.fname||self.dialect.class.name}.cfg"))
        end

        def add(section, clazz=NestedSection)
          throw "section is nil" unless section
          section = Lines::Line.new(section, -1) unless section.kind_of?(Lines::Line)
          section_key=Result.normalize_section_key(section.to_s)

          @sections[section_key] ||= clazz.new(section_key)
          if Result.starts_with_no(section.to_s)
            @sections[section_key].no
          end
          yield(@sections[section_key])  if block_given?
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
          result.sections = deltas[0]
          result
        end
      end

      class SingleValueVerb
        attr_accessor :section,:value
        def initialize(section)
          self.section=section
        end

        def serialize
          [[@no, section , value].compact.join(" ")]
        end

        def self.compare(nu, old)
          return [nu] unless old
          return [old.no] unless nu
          return [nu] unless nu.serialize == old.serialize
          [nil]
        end

        def add(value)
          self.value=value
        end

        def no
          @no="no"
          self.value=nil
          self
        end

        def self.parse_line(line, lines, section, result)
          regexp = line.to_s.strip.end_with?("\"") ? /^(.*) (\"[^"]+\")$/ : /^(.*) ([^\s"]+)$/
          if (line.to_s.strip =~ regexp)
            section.add($1, Ciscian::SingleValueVerb).add($2)
          else
            section.add(line.to_s, Ciscian::SingleValueVerb)
          end
        end
      end

      class VariableVerb
        attr_accessor :key,:values
        def initialize(key)
          self.key=key
          self.values = []
        end

        def add(value)
          self.values << value
          self
        end

        def serialize
          puts "VALUES" + values.to_s
          [eval("\"#{key}\"")]
        end
      end

      class NestedSection
        attr_accessor :section,:sections
        def initialize(section)
          self.sections={}
          self.section=section
        end

        def add(verb, clazz = MultiValueVerb)
          # if verb.respond_to?(:section_key)
          #   clazz=verb
          #   verb=clazz.section_key
          # end
          self.sections[Result.normalize_section_key(verb.to_s)] ||= clazz.new(verb)
        end

        def self.parse_line(line, lines, section, result)
          #binding.pry if line.start_with?("interface")
          if [/^\s*(no\s+|)interface/, /^\s*(no\s+|)vlan/].find{|i| line.to_s.match(i) }
            resultline=Result::Lines::Line.new(result.dialect.clear_interface(line), line.nr)
            section.add(resultline.to_s) do |_section|
              while _line = lines.shift
                break if result.dialect.block_end?(_line.to_s)
                result.parse_line(_line, lines, _section, result)
              end
            end

            if (matchdata = line.to_s.match(Construct::Util::PORTS_DEF_REGEXP))
              ports = Construct::Util::expandRangeDefinition(matchdata[0])
              if (ports.length>1)
                section_to_split=section.sections.delete(resultline.to_s)
                ports.each do |port|
                  section.add(line.to_s.gsub(/#{Construct::Util::PORTS_DEF_REGEXP}/, port)) do |_section|
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

        def serialize
          block=[]
          block << "#{@no}#{section.to_s}"
          unless (@no)
            block += render_verbs(self.sections)
            block << "exit"
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
              (nu.sections.keys + old.sections.keys).sort.each do |k,v|
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

      class MultiValueVerb
        attr_accessor :section,:values
        def initialize(section)
          self.section=section
          self.values = []
        end

        def add(value)
          self.values << value
          self
        end

        def no
          @no="no "
          self
        end

        def serialize
          if @no
            ["#{@no}#{section}"]
          else
            ["#{section} #{values.join(",")}"]
          end
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
      end

      class RangeVerb
        attr_accessor :section,:values
        def initialize(section)
          self.section=section
          self.values = []
        end

        def add(value)
          throw "must be a number \'#{value}\'" unless /^\d+$/.match(value.to_s)
          self.values << value.to_i
          self
        end

        def no
          @no="no "
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
            ["#{@no}#{section}"]
          else
            ["#{section} #{Construct::Util.createRangeDefinition(values)}"]
          end
        end
      end


      class PatternBasedVerb
        attr_accessor :section, :changes

        def initialize(section)
          self.section=section
          self.changes=[]
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
              var_regex = "#{Construct::Util::PORTS_DEF_REGEXP}" unless var_regex
              regex=regex.gsub(var, var_regex)
            end
            regex=regex.gsub(" ", "\\s+")
            regex="^"+regex+"$"
            if (matchdata=line.match(regex))
              values={"pattern" => pattern}
              (1..variables.length).each do |i|
                if find_regex(extract_varname(variables[i-1])).nil?
                  values[variables[i-1]]=Construct::Util.expandRangeDefinition(matchdata[i])
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
          nu_ports=nu.nil? ? {} : nu.integrate
          old_ports=old.nil? ? {} : old.integrate

          result = self.new(self.section)

          key_var = (nu||old).find_key_var
          set_keys = (nu||old).keys_of_set + (old||nu).keys_of_set

          set_keys.each do |key_val|
            variables(self.patterns).each do |v|
              if is_key_value?(v)
                result.add({key_var => key_val})
              elsif is_value?(v)
                result.add({key_var => key_val, v => nu_ports[key_val][v]})
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
                    value_sets[v] = entry[v] if entry[v]
                  elsif self.class.is_value?(v)
                    value_sets[v] = entry[v]
                  else
                    value_sets[v] += entry[v] if entry[v]
                    value_sets[self.class.invert(v)] -= entry[v] if entry[v] && value_sets[self.class.invert(v)]
                  end
                end
              end
            end
          end

          #remove duplicate entries
          sets.each do|key_val,value_sets|
            value_sets.each do |v,set|
              value_sets[v] = set & set
            end
          end

          return sets
        end

        def serialize
          buffer = []
          sets = integrate

          # deactivate grouping, if one variable has a custom regex (i.e. is not a range definition)
          group=true
          self.class.variables(self.class.patterns).each do |v|
            group=false unless self.class.find_regex(self.class.extract_varname(v)).nil?
          end

          self.class.patterns.each do |pattern|
            sets.each do |key_val,value_sets|
              index = 0
              begin
                substitution=false
                result = pattern
                self.class.find_variables(pattern).each do |v|
                  if (group)
                    result = result.gsub(v, Construct::Util.createRangeDefinition(value_sets[v])) unless value_sets[v].empty?
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

      class Vlan  < OpenStruct
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

      def self.clazz(name)
        ret = {
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
        }[name]
        throw "class not found #{name}" unless ret
        ret
      end

      def self.create_host(name, cfg)
        cfg['name'] = name
        cfg['result'] = nil
        host = Host.new(cfg)
        host.result = Result.new(host)
        host
      end

      def self.create_interface(name, cfg)
        cfg['name'] = name
        clazz(cfg['clazz']).new(cfg)
        #cfg['name'] = name
        #Interface.new(cfg)
      end
    end
  end
end
