module Construqt
  module Flavour
    class Ciscian
      class NestedSection
        attr_accessor :section, :sections
        def initialize(section)
          self.sections = {}
          self.section = section
        end

        def add(verb, clazz = SingleValueVerb)
          section_key = Result.normalize_section_key(verb.to_s)
          sections[section_key] ||= clazz.new(section_key)

          @sections[section_key].no if Result.starts_with_no(verb.to_s)
          @sections[section_key]
        end

        def self.parse_line(line, lines, section, result)
          if [/^\s*(no\s+|)interface/, /^\s*(no\s+|)vlan/].find { |i| line.to_s.match(i) }
            resultline = Result::Lines::Line.new(result.dialect.clear_interface(line), line.nr)
            section.add(resultline.to_s, NestedSection) do |_section|
              _section.virtual if result.dialect.is_virtual?(resultline.to_s)
              while _line = lines.shift
                break if result.dialect.block_end?(_line.to_s)
                result.parse_line(_line, lines, _section, result)
              end
            end

            if (matchdata = line.to_s.match(Construqt::Util::PORTS_DEF_REGEXP))
              ports = Construqt::Util.expandRangeDefinition(matchdata[0])
              if ports.length > 1
                section_to_split = section.sections.delete(resultline.to_s)
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

        def render_verbs(_verbs)
          block = []
          sections.keys.sort.each do |key|
            verb = sections[key]
            block << verb.serialize.map { |i| "  #{i}" }
          end

          block
        end

        def no
          @no = 'no '
          @sections = {}
          self
        end

        def no?
          @no
        end

        def yes
          @no = nil
          self
        end

        def virtual
          @virtual = true
          self
        end

        def serialize
          block = []
          if !sections.empty? || (sections.empty? && @virtual) || (@no && @virtual)
            block << "#{@no}#{section}"
            unless @no
              block += render_verbs(sections)
              block << 'exit'
            end
          end

          block
        end

        def self.compare(nu, old)
          return [nu] unless old
          return [old.no] unless nu
          throw "classes must match #{nu.class.name} != #{old.class.name}" unless nu.class == old.class

          if (nu.serialize == old.serialize)
            return [nil]
          else
            if nu.no?
              return [nu]
            else
              delta = nu.class.new(nu.section)
              (nu.sections.keys + old.sections.keys).uniq.sort.each do |k, _v|
                nu_section = nu.sections[k]
                old_section = old.sections[k]
                comps = (nu_section || old_section).class.compare(nu_section, old_section)
                throw "class #{(nu_section || old_section).class.name} returns illegal nil in compare method" unless comps
                comps.compact.each do |comp|
                  delta.sections[comp.section] = comp
                end
              end

              return [delta]
            end
          end
        end
      end
    end
  end
end
