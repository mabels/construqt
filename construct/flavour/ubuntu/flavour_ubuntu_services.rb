
module Construct
module Flavour
module Ubuntu
module Services
  class DhcpV4Relay
    def initialize(service)
      @service = service
    end
    def prefix(unused, unused2)
    end
    def render(host, ifname, iface, writer)
      binding.pry
      return unless iface.address && iface.address.first_ipv4
      return if @service.servers.empty?
      writer.lines.up("/usr/sbin/dhcrelay -pf /run/dhcrelay-v4.#{ifname}.pid -d -q -4 -i #{ifname} #{@service.servers.map{|i| i.to_s}.join(' ')}")
      writer.lines.down("kill `/run/dhcrelay-v4.#{ifname}.pid`")
    end
  end
  class DhcpV6Relay
    def initialize(service)
      @service = service
    end
    def prefix(unused, unused2)
    end
    def render(host, ifname, iface, writer)
      return unless iface.address && iface.address.first_ipv6
      return if @service.servers.empty?
      writer.lines.up("/usr/sbin/dhcrelay -pf /run/dhcrelay-v6.#{ifname}.pid -d -q -6 -i #{ifname} #{@service.servers.map{|i| i.to_s}.join(' ')}")
      writer.lines.down("kill `/run/dhcrelay-v6.#{ifname}.pid`")
    end
  end
  class Radvd
    def initialize(service)
      @service = service
    end
    def prefix(unused, unused2)
    end
    def render(host, ifname, iface, writer)
#      binding.pry
      return unless iface.address && iface.address.first_ipv6
      writer.lines.up("/usr/sbin/radvd -C /etc/network/radvd.#{ifname}.conf -p /run/radvd.#{ifname}.pid")
      writer.lines.down("kill `cat /run/radvd.#{ifname}.pid`")
      host.result.add(self, <<RADV, Construct::Resource::Rights::ROOT_0644, "etc", "network", "radvd.#{ifname}.conf")
interface #{ifname}
{
        AdvManagedFlag on;
        AdvSendAdvert on;
        #AdvAutonomous on;
        AdvLinkMTU 1480;
        AdvOtherConfigFlag on;
        MinRtrAdvInterval 3;
        MaxRtrAdvInterval 60;
        prefix #{iface.address.first_ipv6.network.to_string}
        {
                AdvOnLink on;
        #       AdvAutonomous on;
                AdvRouterAddr on;
        };

};
RADV
    end
  end

  def self.get_renderer(service)
     factory = {
      Construct::Services::DhcpV4Relay => DhcpV4Relay,
      Construct::Services::DhcpV6Relay => DhcpV6Relay,
      Construct::Services::Radvd => Radvd
     }
     found = factory.keys.find{ |i| service.kind_of?(i) }
     throw "service type unknown #{service.name} #{service.class.name}" unless found
     factory[found].new(service)
  end
end
end
end
end
