module Construqt
  module Flavour
    class Ciscian
      class RangeVerb
        attr_accessor :section, :values
        def initialize(section)
          self.section = section
          self.values = []
        end

        def add(value)
          # throw "must be a number \'#{value}\'" unless /^\d+$/.match(value.to_s)
          values << value # .to_i
          self
        end

        def no
          @no = 'no '
          self
        end

        def yes
          @no = nil
          self
        end

        def self.compare(nu, old)
          return [nu] unless old
          return [old.no] unless nu
          throw "classes must match #{nu.class.name} != #{old.class.name}" unless nu.class == old.class
          if (nu.serialize == old.serialize)
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
    end
  end
end
