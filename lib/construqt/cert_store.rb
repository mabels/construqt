
module Construqt
  class CertStore
    class Tuple
      attr_reader :name, :content
      def initialize(name, content)
        @name = name
        @content = content
      end
    end

    def initialize(region)
      @region = region
      @private = {}
      @cacerts = {}
      @certs = {}
    end

    def add_private(name, cfg)
      throw "private exists #{name}" if @private[name]
      @private[name] = cfg
    end

    def add_cacert(name, cfg)
      throw "cacerts exists #{name}" if @cacerts[name]
      @cacerts[name] = cfg
    end

    def add_cert(name, cfg)
      throw "certs exists #{name}" if @certs[name]
      @certs[name] = cfg
    end

    def get_cert(name)
      ret = @certs[name]
      if ret
        ret = Tuple.new(name, ret)
      end
      ret
    end

    def all
      {
        "cacerts" => @cacerts,
        "certs" => @certs,
        "private" => @private
      }
    end

    def all_private
      @private
    end

    def all_cacerts
      @cacerts
    end

    def all_certs
      @certs
    end

  end
end
