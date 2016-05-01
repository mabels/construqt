module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          module Firewall
            class BeginEndMiddle
              attr_reader :begin, :middle, :end

              def initialize
                @begin = ""
                @middle = ""
                @end = ""
              end

              def push_begin(str)
                @begin = @begin + Construqt::Util.space_before(str)
                self
              end

              def push_middle(str)
                @middle = @middle + Construqt::Util.space_before(str)
                self
              end

              def push_end(str)
                @end = @end + Construqt::Util.space_before(str)
                self
              end
            end
          end
        end
      end
    end
  end
end
