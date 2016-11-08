module Construqt
  class Dns
    def initialize(reference, parent = nil)
      @reference = reference
      @parent = parent
      @search = nil
      @nameservers = nil
    end
    def inspect
      "@<#{self.class.name}:#{self.object_id} search=#{@search} nameservers=#{nameservers}>"
    end
    def search=(a)
      @search = a
    end
    def search
      return @search if @search
      return @parent.dns_resolver.search if @parent
      nil
    end
    def nameservers=(a)
      @nameservers = a
    end

    def nameservers
      return @nameservers if @nameservers
      return @parent.dns_resolver.nameservers if @parent
      nil
    end
  end
end
