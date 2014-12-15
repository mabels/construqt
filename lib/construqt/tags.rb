
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

    def self.find(tag, clazz = nil)
      #binding.pry
      ret = (@tags[tag] || []).select{|o| clazz.nil? || o.instance_of?(clazz.class) || (clazz.kind_of?(Proc) && clazz.call(o)) }
      Construqt.logger.warn("tag #{tag} #{clazz.inspect} empty result") if ret.empty?
      ret
    end

    def self.ips_net(tag, family)
      #ip_module = family==Construqt::Addresses::IPV4 ? IPAddress::IPv4: IPAddress::IPv6
      IPAddress.summarize((@tags[tag]||[]).map do |obj|
        if obj.kind_of?(IPAddress) || obj.kind_of?(Construqt::Addresses::CqIpAddress)
          obj
        elsif obj.respond_to? :ips
          obj.ips
        elsif obj.kind_of?(Construqt::Flavour::HostDelegate)
          #binding.pry
          res = obj.interfaces.values.map do |i|
            i.delegate.address.ips.map do |a|
              prefix = a.ipv4? ? 32 : 128
              ret = IPAddress.parse("#{a.to_s}/#{prefix}")
              puts "ADR=#{tag} #{ret.to_string} #{a.to_s}"
              ret
            end
          end.flatten
          puts "HOST=>#{tag} #{res.map{|i| i.to_string }}"
          res
        else
          nil
        end
      end.flatten.compact.select do |i|
        (((family==Construqt::Addresses::IPV4||family==IPAddress::IPv4) && i.ipv4?) ||
         ((family==Construqt::Addresses::IPV6||family==IPAddress::IPv6) && i.ipv6?))
      end)
    end
  end
end
