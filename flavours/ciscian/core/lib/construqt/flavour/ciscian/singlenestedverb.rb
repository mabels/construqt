module Construqt
  module Flavour
    class Ciscian
      class SingleValueVerb
        attr_accessor :section, :value
        def initialize(section)
          self.section = section
        end

        def serialize
          val = @quotes ? "\"#{value}\"" : value
          [[@no, section, val].compact.join(' ')]
        end

        def self.compare(nu, old)
          return [nu] unless old
          # return no changes (empty list) if old configuration of single value verb (default) is not explicitly reconfigured in new configuration:
          return [] unless nu
          return [nu] unless nu.serialize == old.serialize
          [nil]
        end

        def add(value)
          self.value = value
          self
        end

        def no
          @no = 'no'
          self.value = nil
          self
        end

        def yes
          @no = nil
          self
        end

        def quotes
          @quotes = true
          self
        end

        def self.parse_line(line, _lines, section, _result)
          quotes = line.to_s.strip.end_with?("\"")
          regexp = quotes ? /^\s*((no|).*) \"([^"]+)\"$/ : /^\s*((no|).*) ([^\s"]+)$/
          if line.to_s.strip =~ regexp
            key = Regexp.last_match(1)
            val = Regexp.last_match(3)
            sec = section.add(key, Ciscian::SingleValueVerb).add(val)
            sec.quotes if quotes
          else
            section.add(line.to_s, Ciscian::SingleValueVerb)
          end
        end
      end
    end
  end
end
