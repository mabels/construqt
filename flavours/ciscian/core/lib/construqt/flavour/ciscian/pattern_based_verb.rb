module Construqt
  module Flavour
    class Ciscian
      class PatternBasedVerb
        attr_accessor :section, :changes

        def initialize(section)
          self.section = section
          self.changes = []
        end

        def yes
        end

        def add(entry)
          changes << entry
          self
        end

        def self.invert(a)
          return a.gsub(/\+/, '-') if a.match(/\+/)
          return a.gsub(/\-/, '+') if a.match(/\-/)
          throw "cannot invert #{a}"
        end

        def self.variables(patterns)
          variables = []
          patterns.each do |pattern|
            variables += find_variables(pattern)
          end

          variables
        end

        def self.find_variables(pattern)
          pattern.scan(/{[^}]+}/)
        end

        def self.parse_line(line, _lines, section, _result)
          entry = matches(patterns, line.to_s)
          return false unless entry
          section.add(self.section, self).add(entry)
          true
        end

        def self.find_regex(_varname)
          nil
        end

        def self.extract_varname(variable)
          matchdata = variable.match(/{(\+|\-|\=|\*)([^}]+)}/)
          throw "could not extract varname from #{variable}" unless matchdata
          matchdata[2]
        end

        def self.matches(patterns, line)
          patterns.each do |pattern|
            variables = find_variables(pattern)
            regex = pattern
            variables.each do |var|
              var_regex = find_regex(extract_varname(var))
              var_regex = "#{Construqt::Util::PORTS_DEF_REGEXP}" unless var_regex
              regex = regex.gsub(var, var_regex)
            end

            regex = regex.gsub(' ', '\\s+')
            regex = '^' + regex + '$'
            if (matchdata = line.match(regex))
              values = { 'pattern' => pattern }
              (1..variables.length).each do |i|
                if find_regex(extract_varname(variables[i - 1])).nil?
                  values[variables[i - 1]] = Construqt::Util.expandRangeDefinition(matchdata[i])
                else
                  values[variables[i - 1]] = [matchdata[i]]
                end
              end

              return values
            end
          end

          false
        end

        def self.compare(nu, old)
          return [] if (nu.serialize == old.serialize) unless nu.nil? || old.nil?

          nu_ports = nu.nil? ? {} : nu.integrate
          old_ports = old.nil? ? {} : old.integrate

          result = new(section)

          key_var = (old || nu).find_key_var
          set_keys = (old || nu).keys_of_set + (nu || old).keys_of_set

          set_keys.each do |key_val|
            variables(patterns).each do |v|
              if is_key_value?(v)
                result.add(key_var => key_val)
              elsif is_value?(v)
                result.add(key_var => key_val, v => (nu_ports[key_val] && nu_ports[key_val][v]) ? nu_ports[key_val][v] : nil)
              else
                set = []
                set += nu_ports[key_val][v] if nu_ports[key_val]
                set += old_ports[key_val][invert(v)] if old_ports[key_val] && old_ports[key_val][invert(v)]
                set -= nu_ports[key_val][invert(v)] if nu_ports[key_val] && nu_ports[key_val][invert(v)]
                set -= old_ports[key_val][v] if old_ports[key_val]
                result.add(key_var => key_val, v => set) if set.length > 0
              end
            end
          end

          [result]
        end

        def self.is_key_value?(v)
          !v.nil? && v.start_with?('{*')
        end

        def self.is_value?(v)
          !v.nil? && v.start_with?('{=')
        end

        def find_key_var
          # find variable for key
          key_var = nil
          changes.each do |entry|
            entry.keys.each do |v|
              if self.class.is_key_value?(v)
                throw 'can only have one key value variable in pattern {*var}' if !key_var.nil? && key_var != v
                key_var = v
              end
            end
          end

          key_var
        end

        def keys_of_set
          keys = []

          key_var = find_key_var

          if key_var
            changes.each do |entry|
              keys << entry[key_var] if entry[key_var]
            end
          end

          return keys unless keys.empty?
          [nil]
        end

        def integrate
          set_keys = keys_of_set

          # initialize sets
          sets = {}
          set_keys.each do |key_val|
            sets[key_val] = {}
          end

          # initialize start values of values inside sets
          set_keys.each do |key_val|
            self.class.variables(self.class.patterns).each do |v|
              if self.class.is_key_value?(v)
                sets[key_val][v] = key_val
              elsif self.class.is_value?(v)
                sets[key_val][v] = nil
              else
                sets[key_val][v] = []
              end
            end
          end

          key_var = find_key_var
          changes.each do |entry|
            sets.each do|key_val, value_sets|
              value_sets.each do |v, _set|
                if (entry[key_var] == key_val)
                  if self.class.is_key_value?(v)
                    value_sets[v] = entry[v]
                  elsif self.class.is_value?(v)
                    value_sets[v] = entry[v]
                  else
                    value_sets[v] += entry[v] if entry[v]
                    # remove duplicates without changing insertion order:
                    value_sets[v] = value_sets[v].reverse.uniq.reverse

                    value_sets[self.class.invert(v)] -= entry[v] if entry[v] && value_sets[self.class.invert(v)]
                  end
                end
              end
            end
          end

          sets
        end

        def always_select_empty_pattern
          false
        end

        def determine_output_patterns(value_sets)
          output_patterns = []
          empty_pattern = nil
          self.class.patterns.each do |pattern|
            pvs = self.class.find_variables(pattern)
            if pvs.empty?
              empty_pattern = pattern
            else
              pvs.each do |pv|
                if !value_sets[pv].nil? && !value_sets[pv].empty?
                  output_patterns << pattern
                  break
                end
              end
            end
          end

          output_patterns.unshift(empty_pattern) if (output_patterns.empty? || always_select_empty_pattern) && !empty_pattern.nil?
          output_patterns
        end

        def group?
          true
        end

        def prefer_no_verbs?
          false
        end

        def prefer_no_verbs_sort(buffer)
          buffer.sort do |a, b|
            ret = 0
            ret = Construqt::Util.rate_higher('no ', a, b) if ret == 0
            ret = a <=> b if ret == 0
            ret
          end
        end

        def serialize
          buffer = []
          sets = integrate

          sets.each do |_key_val, value_sets|
            determine_output_patterns(value_sets).each do |pattern|
              index = 0
              i = 0
              begin
                substitution = false
                result = pattern
                i += 1
                self.class.find_variables(pattern).each do |v|
                  if self.group?
                    if !value_sets[v].is_a?(Array) && (self.class.is_value?(v) || self.class.is_key_value?(v))
                      result = result.gsub(v, value_sets[v].to_s) unless value_sets[v].nil? || value_sets[v].to_s.empty?
                    else
                      result = result.gsub(v, Construqt::Util.createRangeDefinition(value_sets[v])) unless value_sets[v].nil? || value_sets[v].empty?
                    end
                  else
                    if index < value_sets[v].length
                      result = result.gsub(v, value_sets[v][index])
                      substitution = true
                    end
                  end
                end

                buffer << result if self.class.find_variables(result).empty?
                index += 1
              end while substitution
            end
          end

          buffer = prefer_no_verbs_sort(buffer) if prefer_no_verbs?

          buffer
        end
      end
    end
  end
end
