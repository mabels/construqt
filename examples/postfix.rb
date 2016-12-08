
class Smtp

    include Construqt::Util::Chainable
    attr_reader :name
    attr_accessor :services
    chainable_attr_value :server_iface, nil
    def initialize(name = "")
      @name = name
    end

end

module Postfix
  class Factory
    attr_reader :machine
    def start(service_factory)
      @machine = service_factory.machine.service_type(Smtp)
    end

    def produce(host, srv_inst, ret)
      Action.new
    end
  end

  class Action
    def build_interface(host, ifname, iface, writer)
    end
  end


#  POSTFIX = :postfix
#
#    def self.add_component(cps)
#      cps.register(POSTFIX).add('postfix')
#    end
#
#    module Renderer
#      module Nixian
#        class Ubuntu
#          def initialize(service)
#            @service = service
#          end
#          def vrrp(host, ifname, iface)
#            puts "Smtp:vrrp"
#          end
#          def build_interface(host, ifname, iface, writer, family = nil)
#                return unless iface.address
#                host.result.add(self, <<MAINCF, Construqt::Resources::Rights.root_0644(POSTFIX), "etc", "postfix", "main.cf")
## #{@service.get_server_iface.host.name} #{@service.get_server_iface.address.first_ipv4}
#inet_protocols = all
#myhostname = #{iface.host.name}
#mynetworks = #{iface.address.first_ipv4.network.to_string} #{iface.address.first_ipv6 && iface.address.first_ipv6.network.to_string}
#MAINCF
#
#          end
#       end
#      end
#    end
#  end

    #Construqt::Flavour::Nixian::Dialect::Ubuntu::Services.add_renderer(Postfix::Smtp, Postfix::Smtp::Renderer::Nixian::Ubuntu)
    #smtp_service = Smtp.new("POSTFIX");
    #region.services.add(smtp_service)
  #

  def self.run(region)
    postfix_gw = region.hosts.add("postfix-gw", "flavour" => "nixian", "dialect" => "ubuntu") do |host|
      region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                   :description=>"#{host.name} lo",
                                   "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
      host.configip = host.id ||= Construqt::HostId.create do |my|
        my.interfaces << extern_if = region.interfaces.add_device(host, "eth0", "mtu" => 1500,
                                          "address" => region.network.addresses
                                                          .add_ip("192.168.200.17/24")
                                                          .add_route("0.0.0.0/0", "192.168.200.1")
                                         )
        extern_if.services.add(Smtp.new.server_iface(extern_if))
      end
    end
    5.times do |i|
      postfix_clt = region.hosts.add("postfix-clt-#{i}", "flavour" => "nixian", "dialect" => "ubuntu") do |host|
        region.interfaces.add_device(host, "lo", "mtu" => "9000",
                                     :description=>"#{host.name} lo",
                                     "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))
        host.configip = host.id ||= Construqt::HostId.create do |my|
          my.interfaces << extern_if = region.interfaces.add_device(host, "eth0", "mtu" => 1500,
                                            "address" => region.network.addresses
                                                            .add_ip("192.168.200.#{100+i}/24")
                                                            .add_route("0.0.0.0/0", "192.168.200.1")
                                           )
          extern_if.services.add(Smtp.new)
        end
      end
    end
  end
end
#end
