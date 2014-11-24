
module Construct
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

    def self.find(tag, clazz = nil)
      #binding.pry
      ret = (@tags[tag] || []).select{|o| clazz.nil? || o.kind_of?(clazz) }
      Construct.logger.warn("tag #{tag} #{clazz.inspect} empty result") if ret.empty?
      ret
    end

    def self.ips_net(tag, family)
      ip_module = family==Construct::Addresses::IPV4 ? IPAddress::IPv4: IPAddress::IPv6
      IPAddress::IPv4::summarize(*(@tags[tag]||[]).map do |obj|
        if obj.kind_of?(IPAddress)
          obj
        else
          obj.ips
        end
      end.flatten.compact.select do |i|
        (family==Construct::Addresses::IPV4 && i.ipv4?) ||
          (family==Construct::Addresses::IPV6 && i.ipv6?)
      end)
    end
  end
end
