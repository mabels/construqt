module Construct
module Flavour
module Mikrotik

  class Schema

    def initialize
      @required = false
      @key = false
      @noset = false
      @type = nil
      @default = nil
    end

    def type
      @type
    end

    def required
      @required = true
      self
    end
    def required?
      @required
    end

    def key
      @key = true
      self
    end
    def key?
      @key
    end

    def noset
      @noset = true
      self
    end
    def noset?
      @noset
    end

    class Int
      def self.serialize(val)
        return val if val.nil?
        throw "only 0-9 are allowed [#{val}]" unless val.to_s.match(/^[0-9]+$/)
        return val.to_i
      end
    end
    def int
      @type = Int
      self
    end

    class String
      def self.serialize(val)
        val = val.strip
        return '""' if val.nil? || val.empty?
        return val.to_s.inspect.gsub('$', '\\$')
      end
    end
    def string
      @type = String
      self
    end

    class Identifier
      def self.serialize(val)
        throw "only a-zA-Z0-9_- are allowed [#{val}]" unless val.match(/^[a-zA-Z0-9\-_]+$/)
        return val.to_s
      end
    end
    def identifier
      @type = Identifier
      self
    end

    class Port
      def self.serialize(val)
        val = '0' if val == 'any'
        throw "only 0-9 are allowed [#{val}]" unless val.match(/^([Z0-9]+)$/)
        return val.to_s
      end
    end
    def port
      @type = Port
      self
    end

    class Identifiers
      def self.serialize(val)
        '"'+val.split(',').map{|i| Identifier.serialize(i) }.join(',').to_s+'"'
      end
    end
    def identifiers
      @type = Identifiers
      self
    end

    class Address
      def self.serialize(val)
        throw "only 0-9:\.\/ are allowed #{val}" unless val.match(/^[a-fA-F0-9:\.\/]+$/)
        return val.to_s
      end
    end
    def address
      @type = Address
      self
    end

    class Addresses
      def self.serialize(val)
        val.split(',').map{|i| Address.serialize(i) }.join(',').to_s
      end
    end
    def addresses
      @type = Addresses
      self
    end

    def get_default
      @default
    end

    def default(val)
      @default = val
      self
    end

    def self.default(val)
      Schema.new.default(val)
    end

    def self.int
      Schema.new.int
    end

    def self.string
      Schema.new.string
    end

    def self.port
      Schema.new.port
    end

    def self.identifier
      Schema.new.identifier
    end

    def self.identifiers
      Schema.new.identifiers
    end

    def self.addresses
      Schema.new.addresses
    end

    def self.address
      Schema.new.address
    end


    def self.key
      Schema.new.key
    end

    def self.noset
      Schema.new.noset
    end

    def self.required
      Schema.new.required
    end
  end
end
end
end
