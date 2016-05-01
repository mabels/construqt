module Construqt
  module Firewalls
    class FwIpAddresses
      def initialize
        @list = []
      end

      def to_s
        "#<#{self.class.name}:#{self.object_id}:#[#{@list.map{|i| i.to_s}.join(":")}]>"
      end

      def empty?
        @list.empty?
      end

      def missing?
        !!@list.find{|i| i.missing?}
      end

      def size
        @list.length
      end

      def set_list(list)
        @list = list
        self
      end

      def merge!(&block)
        @list = @list.map do |ip|
          block.call(ip).map { |i| ip.merge(i) }
        end.flatten
        @cached_list = false
      end

      def map(&block)
        _list.map{|i| block.call(i) }
      end

      def each_without_missing(&block)
        _list.each{|i| !i.missing? && block.call(i) }
      end

      def size_without_missing
        _list.select{|i| !i.missing?}.size
      end

      def first
        _list.find{|i| !i.missing?}
      end

      #        class FwIpAddressList
      #          def initialize(list)
      #            @list = list
      #          end

      #          def empty?
      #            @list.empty?
      #          end

      #
      #          def size
      #            @list.size
      #          end

      #          def size_without_missing
      #            @list.select{|fwaddr| !fwaddr.missing? }.size
      #          end

      #          def map(&block)
      #            @list.map{|i| block.call(i) }
      #          end

      #        end

      def _list
        # this is slow i cache now the result
        if @cached_list && @cached_list.size == @list.size
          return @cached_list.list
        end

        missing = @list.select{|fwaddr| fwaddr.missing? }[0..0]
        list = @list.select{|fwaddr| !fwaddr.missing? }.map{|i| i.ip_addr}
        #puts ">>>#{missing} #{list}"
        ret = IPAddress.summarize(list).map{|i| FwIpAddress.new.set_ip_addr(i) }+missing
        @cached_list = OpenStruct.new(:list => ret, :size => @list.size)
        ret
      end

      def add_missing(token, family)
        @list << FwIpAddress.missing(FwToken.new(token), family)
      end

      def add_ip_addrs(ip_addrs)
        ip_addrs.each do |ipaddr|
          throw "ipaddr have to be ipaddress but is #{ipaddr.class.name} #{ipaddr}" unless ipaddr.kind_of?(IPAddress)
          @list << FwIpAddress.new.set_ip_addr(ipaddr)
        end
      end

      def add_fwipaddresses(fw_addrs)
        fw_addrs.each do |fwaddr|
          throw "fwaddr have to be fwipaddress but is #{fwaddr.class.name}" unless fwaddr.kind_of?(FwIpAddress)
          @list << fwaddr
        end
      end
    end
  end
end
