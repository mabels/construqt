
module Construqt
  module Tags
    class ResolverNet
      attr_reader :tag
      attr_reader :family
      def initialize(tag, family)
        @tag = tag
        @family = family
      end
      def resolv()
        Construqt::Tags.ips_net(tag, family)
      end
    end
    class ResolverAdr
      attr_reader :tag
      attr_reader :family
      def initialize(tag, family)
        @tag = tag
        @family = family
      end
      def resolv()
        Construqt::Tags.ips_hosts(tag, family)
      end
    end
    class ResolverAdrNet
      def initialize(adr_tag, net_tag, family)
        @adr_tag = ResolverAdr.new(adr_tag, family)
        @net_tag = ResolverNet.new(net_tag, family)
      end
      def resolv()
        # binding.pry
        IPAddress.summarize(@adr_tag.resolv+@net_tag.resolv)
      end
    end

    TAGS = {}
    OBJECT_ID_TAGS = {}
    def self.join(tags, obj)
      tags && tags.sort.uniq.each do |tag|
        TAGS[tag] ||= []
        TAGS[tag] << obj unless TAGS[tag].include?(obj)
      end
      if obj.respond_to? :tags
        obj.tags = tags
      end
      OBJECT_ID_TAGS[obj.object_id] ||= []
      OBJECT_ID_TAGS[obj.object_id] = (OBJECT_ID_TAGS[obj.object_id] + tags).uniq
    end

    def self.add(tag_str, &block)
      parsed = self.parse(tag_str)
      name = parsed[:first]
      throw "there should be a name [#{tag_str}]" unless name
      obj = block.call(name, parsed['#'])
      self.join(parsed['#'], obj) if parsed['#']
      [name, obj]
    end

    def self.resolver_adr(tag, family)
      ResolverAdr.new(tag, family)
    end

    def self.resolver_adr_net(adr_tag, net_tag, family)
      ResolverAdrNet.new(adr_tag, net_tag, family)
    end

    def self.resolver_net(tag, family)
      ResolverNet.new(tag, family)
    end

    def self.from(obj)
      OBJECT_ID_TAGS[obj.object_id]
    end

    def self.resolv(tag)
      return [] unless tag
      parsed = self.parse(tag)
      tags = []
      tags << parsed[:first] if parsed[:first]
      tags = tags + parsed['#'] if parsed['#']
#puts "TAG[#{tag}] + #{tags}"
      tags.map{|i| TAGS[i]}.compact.flatten
    end

    def self.find(tag, clazz = nil)
      ret = resolv(tag).select{|o| clazz.nil? || o.instance_of?(clazz.class) || (clazz.kind_of?(Proc) && clazz.call(o)) }
      Construqt.logger.warn("tag #{tag} #{clazz.inspect} empty result") if ret.empty?
      ret
    end

    def self.ips_net_per_prefix(tag, family)
      pre_prefix = {}
      ips_adr(tag, family).each do |ip|
        family = ip.ipv4? ? Construqt::Addresses::IPV4 : Construqt::Addresses::IPV6
        pre_prefix[family] ||= {}
        pre_prefix[family][ip.prefix] ||= []
        pre_prefix[family][ip.prefix] << ip
      end

      result = {}
      pre_prefix.each do |family, pre_family|
        result[family] ||= {}
        pre_family.each do |prefix, ip_list|
          #puts ip_list.map{|i| i.class.name }.inspect
          result[family][prefix] = IPAddress.summarize(ip_list)
        end
      end

      result
    end

    def self.ips_adr(tag, family)
#puts "ips_adr=>#{tag}"
      resolv(tag).map do |obj|
#puts "resolv=>#{tag} #{obj.class.name}"
        if obj.kind_of?(IPAddress) || obj.kind_of?(Construqt::Addresses::CqIpAddress)
          obj
        elsif obj.respond_to? :ips
          obj.ips
        elsif  obj.kind_of?(Construqt::Flavour::Delegate::DeviceDelegate)
          obj.address.ips
        elsif obj.kind_of?(Construqt::Flavour::Delegate::HostDelegate)
          res = obj.interfaces.values.map do |i|
            if i.address
              i.address.ips
            else
              nil
            end
          end.compact
          res
        else
          nil
        end
      end.flatten.compact.select do |i|
        (((family==Construqt::Addresses::IPV4) && i.ipv4?) ||
         ((family==Construqt::Addresses::IPV6) && i.ipv6?))
#        (((family==Construqt::Addresses::IPV4||family==IPAddress::IPv4) && i.ipv4?) ||
#         ((family==Construqt::Addresses::IPV6||family==IPAddress::IPv6) && i.ipv6?))
      end
    end

    def self.ips_hosts(tag, family)
      IPAddress.summarize(ips_adr(tag, family).map do |i|
        if i.network.eq(i)
          nil
        else
          IPAddress.parse("#{i.to_s}/#{i.ipv4? ? 32 : 128}")
        end
      end.compact)
    end

    def self.ips_net(tag, family)
      IPAddress.summarize(ips_adr(tag, family).map{|i| i.network })
    end



    def self.parse(str, tags = ['#' ,'@' , '!'])
      return {} if str.nil?
      if str.kind_of?(Symbol)
        throw "tags #{tags} are not allowed in symbols" if Regexp.new("[#{tags.join}]").match(str.to_s)
        return { :first => str }
      end
      str_a = str.strip.gsub(/\s/, '').split('')
      return {} if str.empty?
      fill = []
      fwtokens = {}
      key = :first
      found = false
      while (current = str_a.shift)
        if tags.include?(current)
          found = true
          fwtokens[key] ||= []
          fwtokens[key] << fill
          key = current
          fwtokens[key] ||= []
          fill = []
          fwtokens[key] << fill
        else
          fill << current
        end
      end
      fwtokens[key] = [fill] unless found
      ret = {}
      fwtokens.each do |k, v|
        next if v.nil?
        v = v.select{|i| !i.empty? }.map{|i| i.join('') }.sort.uniq
        next if v.empty?
        ret[k] = v
      end
      ret[:first] = ret[:first].first if ret[:first]
      ret
    end

  end
end
