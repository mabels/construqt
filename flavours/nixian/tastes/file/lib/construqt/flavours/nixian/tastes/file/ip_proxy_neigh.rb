module Construqt
  module Flavour
    module Nixian
      module Tastes
        module File
          class IpProxyNeigh
            #attr_reader :taste_type
            #def initialize
            #  @taste_type = Entities::IpProxyNeigh
            #end
            def initialize
              @commit = false
            end
            # def commit(_, __, ___)
            #   binding.pry if @commit
            #   @commit = true
            # end
            def on_add(ud, taste, iface, me)
              return unless me.iface.proxy_neigh
              # binding.pry
              fsrv = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcNetworkNetworkUd::OncePerHost)
              fsrv.up("/etc/network/#{me.iface.name}-IpProxyNeigh-up.sh")
              fsrv.down("/etc/network/#{me.iface.name}-IpProxyNeigh-down.sh")
              #fsrv.down("ip #{ipv}neigh del proxy #{me.ip.to_s} dev #{me.ifname}")
            end
            def activate(ctx)
              @context = ctx
              self
            end

          end
          add(Entities::IpProxyNeigh, IpProxyNeigh)
        end
      end
    end
  end
end
