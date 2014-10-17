
module Construct
  module Tags
    @tags = {} 
    def self.add(tag_str, &block)
      (name, *tags) = tag_str.split(/\s*#\s*/)
      obj = block.call(name, tags)
      #binding.pry
      tags && tags.uniq.each do |tag|
        @tags[tag] ||= []
        @tags[tag] << obj unless @tags[tag].include?(obj)
      end
      [name, obj]
    end
    def self.find(tag, *clazz)
      #binding.pry
      ret = (@tags[tag] || []).select{|o| clazz.nil? || o.kind_of?(clazz.first) }
      Construct.logger.warn("tag #{tag} #{clazz.first.name} empty result") if ret.empty?
      ret
    end
  end
end

