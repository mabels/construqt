module Construqt
  class Addresses
    #
    #
    class NearstRoute
      attr_reader :dst_tag, :options, :routing_table
      def initialize(dst_tag, options, address, routing_table)
        @dst_tag = dst_tag
        @options = options
        @address = address
        @routing_table = routing_table
      end

      def per_host(ips)
        ret = {}
        ips.each do |adr|
          ret[adr.container.interface.host.name] ||= []
          ret[adr.container.interface.host.name] << adr
        end
        ret
      end

      def resolv
        #binding.pry
        ret = []
        dst_parse = Construqt::Tags.parse(self.dst_tag)
        throw "routing tag not allowed in dst #{self.dst_tag}" if dst_parse['!']
        routing_table = self.routing_table || ""


        ips_v4 = Construqt::Tags.ips_adr(self.dst_tag, Construqt::Addresses::IPV4)
        ips_v4_per_host = per_host(ips_v4)
        ips_v6 = Construqt::Tags.ips_adr(self.dst_tag, Construqt::Addresses::IPV6)
        ips_v6_per_host = per_host(ips_v6)
        @address.ips.each do |adr|
            ((adr.ipv4? && ips_v4) or (adr.ipv6? && ips_v6) or []).each do |dst|
              if adr.include?(dst)
                ips_v4_per_host[dst.container.interface.host.name].each do |dst_addr|
                  next if dst_addr.include?(adr)
                  #puts "#{adr.to_s} #{dst.to_s} #{dst.container.interface.host.name} #{dst_addr.to_s}"
#binding.pry
                  ret += @address.build_route(dst_addr.network.to_string, dst.to_s+routing_table, options).resolv
                end
              end
            end
        end
        #
        #
        # ipv6 = OpenStruct.new(:dsts => Construqt::Tags.ips_net(self.dst_tag, Construqt::Addresses::IPV6),
        #                       :vias => Construqt::Tags.ips_hosts(self.via_tag, Construqt::Addresses::IPV6))
        # vias = Construqt::Tags.ips_hosts(self.via_tag, Construqt::Addresses::IPV4)
        # ipv4 = OpenStruct.new(:dsts => Construqt::Tags.ips_net(self.dst_tag, Construqt::Addresses::IPV4),
        #                       :vias => Construqt::Tags.ips_hosts(self.via_tag, Construqt::Addresses::IPV4))
        # [ipv6, ipv4].each do |blocks|
        #   next unless blocks.vias
        #   next unless blocks.dsts
        #   next if blocks.dsts.empty?
        #   #puts ">>>>>>>>>#{self.dst_tag} #{blocks.dsts.map{|i| i.to_s}},#{self.via_tag} #{blocks.vias.map{|i| i.to_s}}"
        #   blocks.vias.each do |via|
        #     blocks.dsts.each do |dst|
        #       ret += @address.build_route(dst.to_string, via.to_s+routing_table, options).resolv
        #     end
        #   end
        # end

        ret
      end
    end
  end
end
