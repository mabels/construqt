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
          [NestedSection, SingleVerb].find do |clazz|
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

        def compare(other)
          result = Result.new(@host)

          nu_root=NestedSection.new("root")
          nu_root.sections.merge!(@sections)
          other_root=NestedSection.new("root")
          other_root.sections.merge!(other.sections)

          result.sections = NestedSection.compare(nu_root, other_root)
          result
        end
      end

      class SingleVerb
        attr_accessor :verb,:value,:section
        def initialize(verb)
          self.verb=verb
          self.section=verb
        end

        def serialize
          [[@no, verb , value].compact.join(" ")]
        end

        def self.compare(nu, old)
          return nu unless old
          return old.no unless nu
          return nu unless nu.serialize == old.serialize
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
          throw "here" if line.to_s=="interface ethernet 1/0/3"
          if (line.to_s =~ /(.*) \"?(\S+)\"?/)
            section.add($1, Ciscian::SingleVerb).add($2)
          else
            section.add(line.to_s, Ciscian::SingleVerb)
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

        def add(verb, clazz = GenericVerb)
          if verb.respond_to?(:section_key)
            clazz=verb
            verb=clazz.section_key
          end
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
          return nu unless old
          return old.no unless nu
          throw "classes must match #{nu.class.name} != #{old.class.name}" unless nu.class == old.class
          if (nu.serialize==old.serialize)
            nil
          else
            if (nu.no?)
              nu
            else
              delta = nu.class.new(nu.section)
              (nu.sections.keys + old.sections.keys).sort.each do |k,v|
                nu_section=nu.sections[k]
                old_section=old.sections[k]
                comp = (nu_section||old_section).class.compare(nu_section, old_section)
                delta.sections[comp.section] = comp if comp
              end
            end
            delta
          end
        end
      end

      class GenericVerb
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
          return nu unless old
          return old.no unless nu
          throw "classes must match #{nu.class.name} != #{old.class.name}" unless nu.class == old.class
          if (nu.serialize==old.serialize)
            nil
          else
            nu
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
          return nu unless old
          return old.no unless nu
          throw "classes must match #{nu.class.name} != #{old.class.name}" unless nu.class == old.class
          if (nu.serialize==old.serialize)
            nil
          else
            nu
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

      class StringVerb < GenericVerb
        def initialize(key)
          super(key)
        end

        def serialize
          ["#{key} #{values.map{|i| i.inspect}.join(",")}"]
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

      def self.clazzes
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

      def self.clazz(name)
        ret = self.clazzes[name]
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
