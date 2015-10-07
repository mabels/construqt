

module Construqt

  class Racks

    attr_reader :region, :racks
    def initialize(region)
      @region = region
      @racks = {}
    end

    class Rack
      attr_accessor :total_high
      attr_accessor :location
      attr_accessor :name
      attr_accessor :description
      attr_accessor :pin
      def initialize(name)
        @name = name
        @entries = {}
      end
      def add_entry(positions, key)
        if /[^0-9]+/.match(position.to_s) && 0 <= position.to_i && position.to_i <= total_high.to_i
          throw "position must be between 0 <= #{total_high} #{position}"
        end
        @entries[position] ||= {}
        throw "entry with key exists #{key} in Rack #{name}" if @entries[position][key]
        entry = Entry.new(key, self)
        @entries[position][key] = entry
        entry
      end

    end

    def add_rack(name)
      throw "Rack with name exist #{name}" if @racks[name]
      rack = Rack.new(name)
      @racks[name] = rack
      rack
    end

    def find_rack(name)
      throw "Rack with name does not exist #{name}" unless @racks[name]
      @racks[name]
    end

  end

end

