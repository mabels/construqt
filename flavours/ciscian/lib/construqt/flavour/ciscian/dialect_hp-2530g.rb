require_relative "dialect_hp-2510g.rb"
module Construqt
  module Flavour
    class Ciscian
      class Hp2530g < Hp2510g
        def self.name
          'hp-2530g'
        end
      end
      Construqt::Flavour::Ciscian.add_dialect(Hp2530g)
    end
  end
end
