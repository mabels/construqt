require_relative './ipsec/ipsec_cert_store'
require_relative './ipsec/ipsec_secret'
require_relative './result'
module Construqt
  module Flavour
    module Nixian
      module Services
        module IpsecStrongSwan
          class Tunnel
            include Construqt::Util::Chainable
            chainable_attr_value :password
            chainable_attr_value :keyexchange
            chainable_attr_value :cipher
            chainable_attr_value :auto

            #chainable_attr_value :keyexchange
            def initialize
              @endpoints = []
            end

            def render_plantuml
              out = []
              out << "#{self.class.name}.password = #{get_password}"
              out << "#{self.class.name}.keyexchange = #{get_keyexchange}"
              out << "#{self.class.name}.cipher = #{get_cipher}"
              out << "#{self.class.name}.auto = #{get_auto}"
              out.join("\n")
            end

            def endpoint_factory(_)
              throw "tunnel only have two endpoints" if @endpoints.length > 2
              # binding.pry
              ret = Endpoint.new(self)
              @endpoints << ret
              @endpoints.first.remote = @endpoints.last
              @endpoints.last.remote = @endpoints.first
              ret
            end
          end
          class Endpoint
            include Construqt::Util::Chainable
            chainable_attr_value :password
            chainable_attr_value :all
            chainable_attr_value :auto
            chainable_attr :any
            chainable_attr :sourceip

            attr_accessor :remote
            attr_reader :local, :tunnel
            def initialize(tunnel)
              @tunnel = tunnel
              @local = self
            end

            def render_plantuml
              out = []
              out << "#{self.class.name}.password = #{get_password}"
              out << "#{self.class.name}.all = #{get_all}"
              out << "#{self.class.name}.auto = #{get_auto}"
              out << "#{self.class.name}.any = #{any?}"
              out << "#{self.class.name}.sourceip = #{sourceip?}"
              out.join("\n")
            end
          end

          class OncePerHost
            attr_reader :ipsec_secret, :ipsec_cert_store
            def initialize #(result_types, host)
              # binding.pry
              # @result_types = result_types
              #@host = host
              @connections = Set.new()
            end

            def attach_host(host)
              @host = host
            end

            def activate(ctx)
              @context = ctx
              result = ctx.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
              @ipsec_secret = Ipsec::IpsecSecret.new(result)
              @ipsec_cert_store = Ipsec::IpsecCertStore.new(result)
              result.add(:ipsec, Construqt::Util.render(binding, "strongswan_header.erb"),
                Construqt::Resources::Rights::root_0644(Construqt::Resources::Component::IPSEC), "etc", "ipsec.conf")
            end

            #def add(*a)
            #  @result.add(*a)
            #end

            def add_connection(service, conn)
              @connections.add([service, conn])
            end

            def render_conn(conn, service)
              out = ["conn #{service}"]
              conn.to_h.each do |k,v|
                out << Util.indent("#{k}=#{v}", 3)
              end

              out.join("\n")
            end

            def commit
              # binding.pry
              @ipsec_secret.commit
              @ipsec_cert_store.commit
              result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)

              result.add(:ipsec, @connections.map{|c| render_conn(c.last, c.first) }.join("\n"),
                         Construqt::Resources::Rights::root_0644(Construqt::Resources::Component::IPSEC),
                         "etc", "ipsec.conf")
            end
          end

          class Action
            attr_reader :host, :service
            def initialize(host, service, sip)
              @host = host
              @service = service #.ipsec
              @service_instance_producer = sip
            end

            def activate(ctx)
              @context = ctx
            end

            def build_config_host#(host, service)
              tunnel = @service_instance_producer.iface.endpoint.tunnel
              remote = @service_instance_producer.iface.endpoint.remote
              local = @service_instance_producer.iface.endpoint.local
              # binding.pry
                if tunnel.transport_family == Construqt::Addresses::IPV6
                  # local_if = host.interfaces.values.find { |iface| iface.address && iface.address.match_address(service.remote.first_ipv6) }
                  transport_left=remote.endpoint_address.get_active_address.first_ipv6.to_s
                  transport_right=local.endpoint_address.get_active_address.first_ipv6.to_s
                  leftsubnet = local.endpoint_address.get_active_address.v6s.map{|i| i.to_s }.first # join(',')
                  rightsubnet = remote.endpoint_address.get_active_address.v6s.map{|i| i.to_s }.first #.join(',')
                  gt = "gt6"
                else
                  # local_if = host.interfaces.values.find { |iface| iface.address && iface.address.match_address(service.remote.first_ipv4) }
                  transport_left=remote.endpoint_address.get_active_address.first_ipv4.to_s
                  transport_right=local.endpoint_address.get_active_address.first_ipv4.to_s
                  leftsubnet = local.endpoint_address.get_active_address.v4s.map{|i| i.to_s }.first # join(',')
                  rightsubnet = remote.endpoint_address.get_active_address.v4s.map{|i| i.to_s }.first #.join(',')
                  gt = "gt4"
                end

                if leftsubnet.nil? or leftsubnet.empty? or
                   rightsubnet.nil? or rightsubnet.empty?
                  throw "we need a transport_left and transport_right for #{local.host.name}-#{remote.host.name}"
                end

                # if local_if.clazz == "vrrp"
                #   writer = host.result.etc_network_vrrp(local_if.name)
                #   writer.add_master("/usr/sbin/ipsec up #{service.host.name}-#{service.other.host.name} &", 1000)
                #   writer.add_backup("/usr/sbin/ipsec down #{service.host.name}-#{service.other.host.name} &", -1000)
                #   local_if.services << Construqt::Services::IpsecStartStop.new
                # else
                # end

                ioph = @context.find_instances_from_type(OncePerHost)
                password = @service.get_password || @service.tunnel.get_password
                ioph.ipsec_secret.add_psk(transport_right, password, tunnel.name)
                ioph.ipsec_secret.add_psk(remote.host.name, password, tunnel.name)

                conn = OpenStruct.new
                conn.leftid=local.host.name
                conn.rightid=remote.host.name
                conn.left=(@service.any? && "%any") || transport_left
                conn.right=(@service.remote.any? && "%any") || transport_right
                conn.leftsubnet=leftsubnet
                if (@service.remote.sourceip?)
                  conn.leftsourceip="%config"
                end

                conn.rightsubnet=rightsubnet
                if (@service.sourceip?)
                  conn.rightsourceip=rightsubnet
                end

                conn.esp=@service.tunnel.get_cipher || "aes256-sha1-modp1536"
                conn.ike=@service.tunnel.get_cipher || "aes256-sha1-modp1536"
                conn.compress="no"
                conn.ikelifetime="60m"
                conn.keylife="20m"
                conn.keyingtries="0"
                conn.keyexchange=@service.tunnel.get_keyexchange || "ike"
                conn.type="tunnel"
                conn.authby="secret"
                conn.dpdaction="restart"
                conn.dpddelay="120s"
                conn.dpdtimeout="180s"
                conn.rekeymargin="3m"
                conn.closeaction="restart"
                # binding.pry
                conn.auto=(@service.get_auto || @service.tunnel.get_auto) || "start"
                conn_name = "#{local.host.name}-#{remote.host.name}"
                ioph.add_connection(conn_name, conn)
                #binding.pry
                up_downer = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::UpDowner::OncePerHost)
                up_downer.add(@host, Tastes::Entities::IpSecConnect.new(conn_name))
              end

            def commit
            end
          end

          class Factory
            attr_reader :machine
            def start(service_factory)
              # binding.pry
              @machine ||= service_factory.machine
                .service_type(Tunnel)
                .service_type(Endpoint)
                .result_type(OncePerHost)
                .depend(UpDowner::Service)
                .depend(Result::Service)
            end

            def produce(host, srv_inst, ret)
              Action.new(host, srv_inst, ret)
            end
          end
        end
      end
    end
  end
end
