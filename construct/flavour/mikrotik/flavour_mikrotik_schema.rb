module Construct
  module Flavour
    module Mikrotik

      class Schema
        module Int
          def self.serialize_compare(schema, val)
            self.serialize(schema, val)
          end

          def self.serialize(schema, val)
            return val if val.nil?
            throw "only 0-9 are allowed [#{val}]" unless val.to_s.match(/^[0-9]+$/)
            return val.to_i
          end
        end

        module Boolean
          def self.serialize_compare(schema, val)
            throw "illegal type #{val.class.name}" unless val.kind_of?(TrueClass) || val.kind_of?(FalseClass)
            val ? 'true' : 'false'
          end

          def self.serialize(schema, val)
            throw "illegal type #{val.class.name}:#{schema.field_name}" unless val.kind_of?(TrueClass) || val.kind_of?(FalseClass)
            val ? 'yes' : 'no'
          end
        end

        module String
          def self.serialize_compare(schema, val)
            self.serialize(schema, val)
          end

          def self.serialize(schema, val)
            return nil if val.nil? && schema.null?
            return '""' if val.nil? || val.strip.empty?
            return val.strip.to_s.inspect.gsub('$', '\\$')
          end
        end

        module Source
          def self.serialize_compare(schema, val)
            nil
          end

          def self.serialize(schema, val)
            return nil if val.nil? && schema.null?
            return '""' if val.nil? || val.strip.empty?
            return "{\n" + val.strip.to_s + "\n}\n"
          end
        end

        module Interval
          def self.serialize_compare(schema, val)
            self.serialize(schema, val)
          end

          def self.serialize(schema, val)
            throw "not in interval format hh:mm:ss" unless /^(\dd)*\d{1,2}:\d{2}:\d{2}$/.match(val)
            return val
          end
        end

        module Identifier
          def self.serialize_compare(schema, val)
            self.serialize(schema, val).inspect
          end

          def self.serialize(schema, val)
            throw "only a-zA-Z0-9_- are allowed [#{val}]" unless val.match(/^[a-zA-Z0-9\-_]+$/)
            return val.to_s
          end
        end

        module Port
          def self.serialize_compare(schema, val)
            self.serialize(schema, val)
          end

          def self.serialize(schema, val)
            val = '0' if val == 'any'
            throw "only 0-9 are allowed [#{val}]" unless val.match(/^([Z0-9]+)$/)
            return val.to_s
          end
        end

        module Identifiers
          def self.serialize_compare(schema, val)
            self.serialize(schema, val, ';')
          end

          def self.serialize(schema, val, joiner=',')
            '"'+val.split(',').map{|i| Identifier.serialize(schema, i) }.join(joiner).to_s+'"'
          end
        end

        module Address
          def self.serialize_compare(schema, val)
            self.serialize(schema, val).inspect
          end

          def self.serialize(schema, val)
            throw "Address:val must be ipaddress #{val.class.name} #{val} #{schema.field_name}" unless val.kind_of?(IPAddress::IPv6) || val.kind_of?(IPAddress::IPv4)
            #        throw "only 0-9:\.\/ are allowed #{val}" unless val.match(/^[a-fA-F0-9:\.\/]+$/)
            return Flavour::Mikrotik.compress_address(val)
          end
        end

        module AddrPrefix
          def self.serialize_compare(schema, val)
            self.serialize(schema, val).inspect
          end

          def self.serialize(schema, val)
            throw "Address:val must be ipaddress #{val.class.name} #{val} #{schema.field_name}" unless val.kind_of?(IPAddress::IPv6) || val.kind_of?(IPAddress::IPv4)
            #        throw "only 0-9:\.\/ are allowed #{val}" unless val.match(/^[a-fA-F0-9:\.\/]+$/)
            return "#{Flavour::Mikrotik.compress_address(val)}/#{val.prefix}"
          end
        end

        module Network
          def self.serialize_compare(schema, val)
            self.serialize(schema, val.network).inspect
          end

          def self.serialize(schema, val)
            throw "Network::val must be ipaddress #{val.class.name} #{val} #{schema.field_name}" unless val.kind_of?(IPAddress::IPv6) || val.kind_of?(IPAddress::IPv4)
            #throw "only 0-9:\.\/ are allowed #{val}" unless val.match(/^[a-fA-F0-9:\.\/]+$/)
            return "#{Flavour::Mikrotik.compress_address(val)}/#{val.prefix}"
          end
        end

        module Addresses
          def self.serialize_compare(schema, val)
            self.serialize(schema, val)
          end

          def self.serialize(schema, val)
            val.map{|i| Address.serialize(schema, i) }.join(',').to_s
          end
        end

        def initialize
          @required = false
          @key = false
          @noset = false
          @type = nil
          @default = nil
          @null = false
          @field_name = nil
        end

        def field_name=(a)
          @field_name=a
        end

        def field_name
          @field_name
        end

        def serialize_compare(val)
          @type.serialize_compare(self, val)
        end

        def serialize(val)
          @type.serialize(self, val)
        end

        def null?
          @null
        end

        def type?
          !@type.nil?
        end

        def null
          @null = true
          self
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

        def int
          @type = Int
          self
        end

        def boolean
          @type = Boolean
          self
        end

        def string
          @type = String
          self
        end

        def source
          @type = Source
          self
        end

        def interval
          @type = Interval
          self
        end

        def identifier
          @type = Identifier
          self
        end

        def port
          @type = Port
          self
        end

        def identifiers
          @type = Identifiers
          self
        end

        def source
          @type = Source
          self
        end

        def interval
          @type = Interval
          self
        end

        def addrprefix
          @type = AddrPrefix
          self
        end

        def address
          @type = Address
          self
        end

        def addresses
          @type = Addresses
          self
        end

        def network
          @type = Network
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

        def self.boolean
          Schema.new.boolean
        end

        def self.string
          Schema.new.string
        end

        def self.interval
          Schema.new.interval
        end

        def self.source
          Schema.new.source
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

        def self.addrprefix
          Schema.new.addrprefix
        end

        def self.address
          Schema.new.address
        end

        def self.network
          Schema.new.network
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
