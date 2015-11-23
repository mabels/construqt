module Construqt
  module Flavour
    class Ciscian
      class Result
        attr_accessor :host, :sections
        def initialize(host)
          @host = host
          @sections = {}
          throw 'ciscian flavour can only be created with dialect' unless host.dialect
          throw 'ciscian flavour can only be created with type' unless host.type
          #require "construqt/flavour/ciscian/dialect/#{host.dialect}/#{host.type}.rb"
          #if Ciscian.dialects[host.dialect].nil? ||
          #   Ciscian.dialects[host.dialect][host.type].nil?
          #  throw "cannot load dialect file #{host.dialect}/#{host.type}"
          #end
          #self.dialect = Ciscian.dialects[host.dialect][host.type].new(self)
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
            @lines[@pos - 1]
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
          matchdata = key.match(/^\s*(no\s+|)(.*)/)
          matchdata[2]
        end

        def self.starts_with_no(key)
          key.match(/^\s*no\s+/)
        end

        def parse_line(line, lines, section, result)
          return if dialect.parse_line(line, lines, section, result)
          [NestedSection, SingleValueVerb].find do |clazz|
            clazz.parse_line(line, lines, section, result)
          end
        end

        def serialize
          block = []
          section_keys = @host.flavour.dialect.sort_section_keys(@sections.keys)
          section_keys.each do |key|
            section = @sections[key]
            block += section.serialize
          end
          block
        end

        def commit
          dialect = @host.flavour.dialect
          dialect.commit
          Util.write_str(@host.region, serialize.join("\n"), File.join(@host.name, "#{@host.fname || Construqt::Util.snake_case(dialect.class.name.split("::").last)}.cfg"))
          external = @host.id.interfaces.first.address
          # external_ip=external.first_ipv4.nil? ? external.first_ipv6.to_s : external.first_ipv4.to_s
          external_ip = @host.name
          DeployTemplate.write_template(@host, dialect.class.name, external_ip, 'root', @host.password || @host.region.hosts.default_password)
        end

        def add(section, clazz = SingleValueVerb)
          throw 'section is nil' unless section
          section = Lines::Line.new(section, -1) unless section.is_a?(Lines::Line)
          section_key = Result.normalize_section_key(section.to_s)

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

          nu_root = NestedSection.new('root')
          nu_root.sections.merge!(nu.sections)
          other_root = NestedSection.new('root')
          other_root.sections.merge!(old.sections)

          deltas = NestedSection.compare(nu_root, other_root)
          throw 'illegal state' if deltas.length != 1
          result.sections = deltas[0].sections unless deltas[0].nil?
          result
        end
      end
    end
  end
end
