
module Construqt
  module Tags
    @tags = {}
    @object_id_tags = {}
    def self.add(tag_str, &block)
      (name, *tags) = tag_str.split(/\s*#\s*/)
      obj = block.call(name, tags)
      #binding.pry
      tags && tags.uniq.each do |tag|
        @tags[tag] ||= []
        @tags[tag] << obj unless @tags[tag].include?(obj)
      end
      if obj.respond_to? :tags
        obj.tags = tags
      end
      @object_id_tags[obj.object_id] ||= []
      @object_id_tags[obj.object_id] = (@object_id_tags[obj.object_id] + tags).uniq
      [name, obj]
    end

    def self.from(obj)
      @object_id_tags[obj.object_id]
    end

    def self.resolv(tag)
      return [] unless tag
      ret = tag.split("#").map{|i| @tags[i.strip]}.compact.flatten
      #binding.pry if tag == "ROOMS#V8-OFFICE"
      ret
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
      resolv(tag).map do |obj|
        if obj.kind_of?(IPAddress) || obj.kind_of?(Construqt::Addresses::CqIpAddress)
          obj
        elsif obj.respond_to? :ips
          obj.ips
        elsif obj.kind_of?(Construqt::Flavour::HostDelegate)
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
        (((family==Construqt::Addresses::IPV4||family==IPAddress::IPv4) && i.ipv4?) ||
         ((family==Construqt::Addresses::IPV6||family==IPAddress::IPv6) && i.ipv6?))
      end
    end

    def self.ips_hosts(tag, family)
      IPAddress.summarize(ips_adr(tag, family).map do |i|
        if i.network == i
          nil
        else
          IPAddress.parse("#{i.to_s}/#{i.ipv4? ? 32 : 128}")
        end
      end.compact)
    end

    def self.ips_net(tag, family)
      IPAddress.summarize(ips_adr(tag, family).map{|i| i.network })
    end
  end
end
