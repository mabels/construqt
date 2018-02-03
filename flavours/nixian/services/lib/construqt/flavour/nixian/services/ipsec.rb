require_relative './ipsec/ipsec_cert_store'
require_relative './ipsec/ipsec_secret'
require_relative './result'
module Construqt
  module Flavour
    module Nixian
      module Services
        module Ipsec
          class Service
            include Construqt::Util::Chainable
            chainable_attr_value :keyexchange
            chainable_attr_value :password
            chainable_attr_value :cipher
          end
          class Endpoint
            include Construqt::Util::Chainable
            chainable_attr :any
            chainable_attr :sourceip
            chainable_attr_value :auto
          end

          class OncePerHost
            def initialize #(result_types, host)
              @tunnels = Set.new
              @ifaces = []
            end

            def attach_interface(iface)
              @tunnels.add(iface.endpoint.tunnel)
              @ifaces << iface
            end

            def attach_host(host)
              @host = host
            end

            def activate(ctx)
              @context = ctx
            end

            def render_conn(conn, service)
              out = ["conn #{service.host.name}-#{service.other.host.name}"]
              conn.to_h.each do |k,v|
                out << Util.indent("#{k}=#{v}", 3)
              end
              out.join("\n")
            end

            def get_endpoint_with_default(services)
              x = services.by_type_of(Endpoint)
              return [Endpoint.new] if x.empty?
              return x
            end

            def write_ipsec(ipsec_secret, result, tunnel, locals, remotes)
              binding.pry
              tunnel.services.select{ |s| s.kind_of?(Service) }.each do |tsrv|
                remotes.each do |remote|
                  remote.interfaces.each do |riface|
                    get_endpoint_with_default(iface.services).each do |rendpt|
                      ipsec_secret.add_psk(remote.host.name, rendpt.get_password, tunnel.name)
                      (remote.endpoint_address.get_service_address.ips +
                       remote.endpoint_address.get_address.ips).each do |ipa|
                        ipsec_secret.add_psk(ipa.to_s, rendpt.get_password, tunnel.name)
                      end
                      locals.each do |local|
                        local.interfaces.each do |liface|
                          get_endpoint_with_default(Endpoint).each do |locapt|
                            conn = OpenStruct.new
                            conn.leftid=local.host.name
                            conn.rightid=remote.host.name
                            conn.left=(locapt.any? && "%any") || transport_left
                            conn.right=(rendpt.any? && "%any") || transport_right
                            conn.leftsubnet=leftsubnet
                            if (rendpt.sourceip?)
                              conn.leftsourceip="%config"
                            end
                            conn.rightsubnet=rightsubnet
                            if (locapt.sourceip)
                              conn.rightsourceip=rightsubnet
                            end

                            conn.esp=tunnel.get_cipher || "aes256-sha1-modp1536"
                            conn.ike=tunnel.get_cipher || "aes256-sha1-modp1536"
                            conn.compress="no"
                            conn.ikelifetime="60m"
                            conn.keylife="20m"
                            conn.keyingtries="0"
                            conn.keyexchange=tunnel.get_keyexchange || "ike"
                            conn.type="tunnel"
                            conn.authby="secret"
                            conn.dpdaction="restart"
                            conn.dpddelay="120s"
                            conn.dpdtimeout="180s"
                            conn.rekeymargin="3m"
                            conn.closeaction="restart"
                            conn.auto=locapt.get_auto || "start"

                            result.add(:ipsec, render_conn(conn, service),
                                       Construqt::Resources::Rights::root_0644(
                                         Construqt::Resources::Component::IPSEC),
                                       "etc", "ipsec.conf")
                          end
                        end
                      end
                    end
                  end
                end
              end
            end

            def build_config_host
              result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
              host = @host
              result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
              @tunnels.each do |tunnel|
                endpoints = tunnel.lefts + tunnel.rights
                locals = Set.new(endpoints.select{|ep| ep.host == @host })
                remotes = Set.new(endpoints.select{|ep| ep.host != @host })
                throw "we need atleast one remote and local" if locals.empty? or remotes.empty?

                self.write_ipsec(ipsec_secret, result, tunnel, locals, remotes)
                #
                # result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
                # result.add(EtcNetworkIptables, @etc_network_iptables.commitv4,
                #            Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::FW4),
                #            'etc', 'network', 'iptables.cfg')
                # result.add(EtcNetworkIptables, @etc_network_iptables.commitv6,
                #            Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::FW6),
                #            'etc', 'network', 'ip6tables.cfg')


                result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Packager::OncePerHost)
                result.add_component(Construqt::Resources::Component::IPSEC)
                up_downer = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::UpDowner::OncePerHost)
                up_downer.add(@host, Tastes::Entities::Ipsec.new(locals, remotes))
              end
            end

            def commit
            end
          end

          class Action
          end

          class Factory
            attr_reader :machine
            def start(service_factory)
              # binding.pry
              @machine ||= service_factory.machine
                .service_type(Service)
                .service_type(Endpoint)
                .result_type(OncePerHost)
                .depend(Result::Service)
                .depend(UpDowner::Service)
            end

            def produce(host, srv_inst, ret)
              Action.new
            end
          end
        end
      end
    end
  end
end
