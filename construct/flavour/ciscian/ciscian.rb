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
          require_relative("dialect_#{host.dialect}.rb")
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
          #puts "#{Lines::Line.name} #{section.class.name}"
          section = Lines::Line.new(section, -1) unless section.kind_of?(Lines::Line)
          @sections[section.to_s] ||= clazz.new(section)
          yield(@sections[section.to_s])  if block_given?
          @sections[section.to_s]
        end

        def self.compare(result, my, other)
          my.sections.keys.sort.each do |key|
            section = my.sections[key.to_s]
            other_section = other.sections.delete(key.to_s)
            section.compare(result, other_section)
          end
        end

        def compare(other)
          result = Result.new(@host)
          self.class.compare(result, self, other)
          other.sections.each do |k, v|
            Construct.logger.debug "untouched=>#{v.section}::#{k}"
          end
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
          [[verb , value].compact.join(" ")]
        end

        def compare(section, other)
          return section.add(section) unless other
          return section.add(section) unless self.serialize == other.serialize
        end

        def add(value)
          self.value=value
        end

        def self.parse_line(line, lines, section, result)
          section.add(line, Ciscian::SingleVerb)
        end
      end

      class NestedSection
        attr_accessor :section,:sections
        def initialize(section)
          self.section=section
          self.sections={}
        end

        def add(verb, clazz = GenericVerb)
          if verb.respond_to?(:section_key)
            clazz=verb
            verb=clazz.section_key
          end
          self.sections[verb.to_s] ||= clazz.new(verb)
        end

        def self.parse_line(line, lines, section, result)
          #binding.pry if line.start_with?("interface")
          if ['interface', 'vlan'].find{|i| line.to_s.start_with?(i) }
            section.add(Result::Lines::Line.new(result.dialect.clear_interface(line), line.nr)) do |_section|
              while line = lines.shift
                break if result.dialect.block_end?(line.to_s)
                result.parse_line(line, lines, _section, result)
              end
            end
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

        def serialize
          block=[]
          block << "#{section.to_s}"
          block += render_verbs(self.sections)
          block << "exit"
          block
        end

        def compare(section, other)
          return section.add(self) unless other
          Result.compare(section, self, other)
        end
      end

      class GenericVerb
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
          ["#{key} #{values.join(",")}"]
        end

        def compare(section, other)
          return section.add(self) unless other
          return section.add(self) unless other.serialize == other.serialize
        end
      end

      class RangeVerb
        attr_accessor :key,:values
        def initialize(key)
          self.key=key
          self.values = []
        end

        def add(value)
          throw "must be a number #{value}" unless /^\d+$/.match(value.to_s)
          self.values << value.to_i
          self
        end

        def compare(section, other)
          return section.add(self) unless other
          return section.add(self) unless self.serialize == other.serialize
        end

        def serialize
          ["#{key} #{Construct::Util.createRangeDefinition(values)}"]
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
