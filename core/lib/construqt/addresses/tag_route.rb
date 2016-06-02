module Construqt
  class Addresses
    #
    #
    class TagRoute
      attr_reader :dst_tag, :via_tag, :options, :routing_table
      def initialize(dst_tag, via_tag, options, address, routing_table)
        @dst_tag = dst_tag
        @via_tag = via_tag
        @options = options
        @address = address
        @routing_table = routing_table
      end

      def resolv
        #binding.pry if self.dst_tag == "#FANOUT-DE"
        ret = []
        dst_parse = Construqt::Tags.parse(self.dst_tag)
        throw "routing tag not allowed in dst #{self.dst_tag}" if dst_parse['!']
        via_parse = Construqt::Tags.parse(self.via_tag)
        routing_table = ""
        if via_parse['!']
          if  via_parse['!'].length == 1
            routing_table = '!'+via_parse['!'].first
          else
            throw "only one routing tag allowed #{self.via_tag}"
          end
        end

        #puts ">>>>>>>>>#{self.dst_tag},#{self.via_tag}"
        ipv6 = OpenStruct.new(:dsts => Construqt::Tags.ips_net(self.dst_tag, Construqt::Addresses::IPV6),
                              :vias => Construqt::Tags.ips_hosts(self.via_tag, Construqt::Addresses::IPV6))
        vias = Construqt::Tags.ips_hosts(self.via_tag, Construqt::Addresses::IPV4)
        ipv4 = OpenStruct.new(:dsts => Construqt::Tags.ips_net(self.dst_tag, Construqt::Addresses::IPV4),
                              :vias => Construqt::Tags.ips_hosts(self.via_tag, Construqt::Addresses::IPV4))
        [ipv6, ipv4].each do |blocks|
          next unless blocks.vias
          next unless blocks.dsts
          next if blocks.dsts.empty?
          #puts ">>>>>>>>>#{self.dst_tag} #{blocks.dsts.map{|i| i.to_s}},#{self.via_tag} #{blocks.vias.map{|i| i.to_s}}"
          blocks.vias.each do |via|
            blocks.dsts.each do |dst|
              ret += @address.build_route(dst.to_string, via.to_s+routing_table, options).resolv
            end
          end
        end

        ret
      end
    end
  end
end
