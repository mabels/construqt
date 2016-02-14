
module Construqt
  class CertStore
    class Tuple
      attr_reader :name, :content
      def initialize(name, content)
        @name = name
        @content = content
      end
    end
    class PrivateKey < Tuple
      def initialize(name, content)
        super(name, content)
      end
    end
    class Cert < Tuple
      def initialize(name, content)
        super(name, content)
      end
    end
    class CaCert < Tuple
      def initialize(name, content)
        super(name, content)
      end
    end

    def initialize(region)
      @region = region
      @private = {}
      @cacerts = {}
      @certs = {}
      @packages = {}
    end

    def add_private(name, cfg)
      throw "private exists #{name}" if @private[name]
      @private[name] = PrivateKey.new(name, cfg)
    end

    def add_cacert(name, cfg)
      throw "cacert exists #{name}" if @cacerts[name]
      @cacerts[name] = CaCert.new(name, cfg)
    end

    def add_cert(name, cfg)
      throw "cert exists #{name}" if @certs[name]
      @certs[name] = Cert.new(name, cfg)
    end

    class Package
      attr_reader :name, :key, :cert, :cacerts
      def initialize(name, key, cert, cacerts)
        @name = name
        throw "key is not the right type" unless key.instance_of?(PrivateKey)
        @key = key
        throw "cert is not the right type" unless cert.instance_of?(Cert)
        @cert = cert
        cacerts.each do |cacert|
          throw "cacert is not the right type" unless cacert.instance_of?(CaCert)
        end
        @cacerts = cacerts
      end
    end
    def create_package(name, key, cert, cacerts)
      throw "package exists #{name}" if @packages[name]
      @packages[name] = Package.new(name, key, cert, cacerts)
    end

    def find_package(name)
      throw "package not found #{name}" unless @packages[name]
      @packages[name]
    end

    # def get_cert(name)
    #   ret = @certs[name]
    #   if ret
    #     ret = Tuple.new(name, ret)
    #   end
    #   ret
    # end
    #
    # def all
    #   {
    #     "cacerts" => @cacerts,
    #     "certs" => @certs,
    #     "private" => @private
    #   }
    # end
    #
    # def all_private
    #   @private
    # end
    #
    # def all_cacerts
    #   @cacerts
    # end
    #
    # def all_certs
    #   @certs
    # end

  end
end
