require 'openssl'

module Construqt
  class CertStore
    class PrivateKey
      attr_reader :finger_print, :fname, :ssl
      def initialize(content, fname)
        @ssl = OpenSSL::PKey::RSA.new(content)
        @finger_print = OpenSSL::Digest::SHA256.new(@ssl.to_der).hexdigest
        @fname = fname
      end
      def content
        @ssl.to_pem
      end
    end
    class Cert
      attr_reader :finger_print, :fname, :ssl
      def initialize(content, fname)
        @fname = fname
        @ssl = OpenSSL::X509::Certificate.new(content)
        now = Time.now
        throw "cert #{fname} is not valid" unless @ssl.not_before <= now && now <= @ssl.not_after
        @finger_print = OpenSSL::Digest::SHA256.new(@ssl.to_der).hexdigest
        @is_a = nil
      end
      def set_cert
        @is_a = :is_a_cert
        self
      end
      def set_ca_cert
        @is_a = :is_a_ca_cert
        self
      end
      def is_cert?
        @is_a == :is_a_cert
      end
      def is_ca_cert?
        @is_a == :is_a_ca_cert
      end
      def content
        @ssl.to_pem
      end
    end

    def initialize(region)
      @region = region
      @private = {}
      @certs = {}
      @packages = {}
    end

    def inspect
      "@<#{self.class.name}:#{self.object_id} region=#{@region.name} "+
      "private=[#{@private.keys.join(",")}] "+
      "certs=[#{@certs.keys.join(",")}] "+
      "packages=[#{@packages.values.map{|i| i.inspect}.join(",")}]"
    end

    def split_mime(content, &action)
      ret = []
      state = :wait_for_begin
      type = ""
      block = []
      content.lines.each do |line|
        sline = line.strip
        if state == :wait_for_begin &&
           sline.start_with?("-----BEGIN ") and sline.end_with?("-----")
          #  binding.pry
           type = sline["-----BEGIN ".length...(sline.length-"-----".length)]
           block = []
           state = :wait_for_end
         end
        if state == :wait_for_end
          block.push(line)
          if sline == "-----END #{type}-----"
            # binding.pry
            ret.push action.call(type, block.join(""))
            state = :wait_for_begin
          end
        end
      end
      # binding.pry
      ret
    end

    def get_fname(cfg)
      fname = nil
      if File.exists?(cfg)
        fname = cfg
        cfg = IO.read(fname)
      end
      [fname, cfg]
    end

    def add_private(cfg)
      fname, cfg = get_fname(cfg)
      split_mime(cfg) do |type, pem|
        throw "unknown type" unless type == "PRIVATE KEY"
        pk = PrivateKey.new(cfg, fname)
        # throw "private exists #{pk.finger_print}" if @private[pk.finger_print]
        @private[pk.finger_print] ||= pk
      end
    end

    def add_cacert(cfg)
      fname, cfg = get_fname(cfg)
      split_mime(cfg) do |type, pem|
        throw "unknown type" unless type == "CERTIFICATE"
        ca = Cert.new(cfg, fname).set_ca_cert
        # throw "cacert exists #{ca.finger_print}" if @cacerts[ca.finger_print]
        @certs[ca.finger_print] ||= ca
      end
    end

    def add_cert(cfg)
      fname, cfg = get_fname(cfg)
      split_mime(cfg) do |type, pem|
        throw "unknown type" unless type == "CERTIFICATE"
        cert = Cert.new(cfg, fname)
        # throw "cert exists #{name}" if @certs[ca.finger_print]
        @certs[cert.finger_print] ||= cert
        @certs[cert.finger_print].set_cert
      end
    end

    class Package
      attr_reader :name, :keys, :certs, :cacerts
      def initialize(name, keys, certs, cacerts)
        @name = name
        @keys = Set.new(keys)
        @keys.each do |key|
          throw "key is not the right type" unless key.instance_of?(PrivateKey)
        end
        @certs = Set.new(certs)
        @certs.each do |cert|
          throw "cert is not the right type" unless cert.instance_of?(Cert)
          throw "needs to be a cert" unless cert.is_cert?
        end
        @cacerts = Set.new(cacerts).select{|i| i.is_ca_cert? }
        # binding.pry
        @cacerts.each do |cacert|
          throw "cacert is not the right type #{cacert}" unless cacert.instance_of?(Cert)
          throw "needs to be a ca_cert" unless cacert.is_ca_cert?
        end
      end

      def dump
        Construqt.logger.info "#{name}:"
        Construqt.logger.info "  keys:"
        @keys.each do |key|
          Construqt.logger.info "    #{key.finger_print}"
        end
        Construqt.logger.info "  certs:"
        certs.each do |cert|
          Construqt.logger.info "    #{cert.finger_print}:"
          Construqt.logger.info "      subject:#{cert.ssl.subject.to_s}"
          Construqt.logger.info "      issuer:#{cert.ssl.issuer.to_s}"
        end
        Construqt.logger.info "  cacerts:"
        cacerts.each do |cert|
          Construqt.logger.info "    #{cert.finger_print}:"
          Construqt.logger.info "      subject:#{cert.ssl.subject.to_s}"
          Construqt.logger.info "      issuer:#{cert.ssl.issuer.to_s}"
        end
        Construqt.logger.info "#{name}:"
      end

      def inspect
        "@<#{self.class.name}:#{self.object_id} name=#{name} keys=#{keys.inspect} "+
        "certs=#{certs.inspect} cacerts=#{cacerts.inspect}>"
      end
    end
    def create_package(name, keys, certs, cacerts)
      throw "package exists #{name}" if @packages[name]
      @packages[name] = Package.new(name, keys, certs, cacerts)
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
