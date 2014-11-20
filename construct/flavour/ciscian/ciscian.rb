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

        def parse(lines)
          lines = lines.map{|i| i.strip }
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
          @sections.keys.sort do |a,b|
            match_a=/^(.*[^\d])(\d+)$/.match(a)||[nil,a,1]
            match_b=/^(.*[^\d])(\d+)$/.match(b)||[nil,b,1]
            puts match_a, match_b, a, b
            ret = match_a[1]<=>match_b[1]
            ret = match_a[2].to_i<=>match_b[2].to_i  if ret==0
            ret
          end.each do |key|
            section = @sections[key]
            block += section.serialize
          end

          Util.write_str(block.join("\n"), File.join(@host.name, "#{self.dialect.class.name}.cfg"))
        end

        def add(section, clazz=NestedSection)
          throw "section must not be nil" unless section
          @sections[section] ||= clazz.new(section)
          yield(@sections[section])  if block_given?
          @sections[section]
        end
      end

      class SingleVerb
        attr_accessor :verb,:value
        def initialize(verb)
          self.verb=verb
        end

        def serialize
          [[verb , value].compact.join(" ")]
        end

        def add(value)
          self.value=value
        end

        def self.parse_line(line, lines, section, result)
          section.add(line, Ciscian::SingleVerb)
        end
      end

      class NestedSection
        attr_accessor :section,:verbs
        def initialize(section)
          self.section=section
          self.verbs={}
        end

        def add(verb, clazz = GenericVerb)
          if verb.respond_to?(:section_key)
            clazz=verb
            verb=clazz.section_key
          end

          self.verbs[verb] ||= clazz.new(verb)
        end

        def self.parse_line(line, lines, section, result)
          #binding.pry if line.start_with?("interface")
          if ['interface', 'vlan'].find{|i| line.start_with?(i) }
            section.add(result.dialect.clear_interface(line)) do |_section|
              while line = lines.shift
                break if result.dialect.block_end?(line)
                result.parse_line(line, lines, _section, result)
              end
            end
          end
        end

        def render_verbs(verbs)
          block=[]
          verbs.keys.sort.each do |key|
            verb = verbs[key]
            puts "#{verb.class.name} section=[#{section}] key=[#{key}] [#{verb.serialize}]"
            block << verb.serialize.map{|i| "  #{i}"}
          end
          block
        end

        def serialize
          block=[]
          block << section
          block += render_verbs(self.verbs)
          block << "exit"
          block
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
      end

      class RangeVerb < GenericVerb
        def initialize(key)
          super(key)
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

        def self.header(path)
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
