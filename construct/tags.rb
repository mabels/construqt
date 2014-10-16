
module Construct
  module Tags
    @tags = {} 
    def self.add(tag_str, &block)
      (name, tags) = tag_str.split(/\s*#\s*/)
      obj = block.call(name, tags)
      tags && tags.uniq.each do |tag|
        @tags[tag] ||= []
        @tags[tag] << obj if @tags[tag].include?(obj)
      end
      obj
    end
    def self.find(tag)
      @tags[tag] || []
    end
  end
end

