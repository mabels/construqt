module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          module Firewall
            class ToFrom
              attr_reader :request_direction, :respond_direction, :rule, :ifname, :writer, :section
              def initialize(ifname, rule, section, writer = nil)
                @rule = rule
                @section = section
                @ifname = ifname
                @writer = writer
              end

              def set_writer(writer)
                @writer = writer
                self
              end

              def set_rule(rule)
                @rule = rule
                self
              end

              def request_direction(family)
                RequestDirection.new(self, family)
              end

              def respond_direction(family)
                RespondDirection.new(self, family)
              end
            end
          end
        end
      end
    end
  end
end
