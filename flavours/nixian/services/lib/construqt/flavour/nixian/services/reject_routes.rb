require_relative './result'
module Construqt
  module Flavour
    module Nixian
      module Services
        module RejectRoutes
          class Service
          end

          class OncePerHost
            def activate(ctx)
              @context = ctx
            end
            def attach_host(host)
             @host = host
            end

            def reject_route(route, rtmetric, rtable, direction)
              metric = ""
              metric = " metric #{rtmetric}" if rtmetric > 0
              routing_table = ""
              routing_table = " table #{rtable}" if rtable
              prefix = route.ipv6? ? "-6" : "-4"
              "ip #{prefix} route #{direction} blackhole #{route.to_string} #{metric}#{routing_table}"
            end

            def find_metric(rts, dest, rtable)
              max = 0
# puts "--------->"
              rts.each do |rt|
                rt.address.routes.each do |r|
                  next unless r.is_global?
                  next unless r.dst_addr_or_tag.include?(dest)
                  next unless r.routing_table == rtable
                  if r.options[:metric] && max < r.options[:metric]
                    max = r.options[:metric]
                  end
# binding.pry
# puts "#{dest.to_string} #{max} #{r.dst_addr_or_tag.to_string}"
                end
              end
# puts "---------< #{max} #{dest.to_string}"
              max
            end
            def post_interfaces # (host, service)
              result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
              global_routes = {}
              @host.interfaces.values.each do |iface|
                iface.address.routes.each do |rt|
                  next unless rt.is_global?
                  global_routes[rt.routing_table] ||= []
                  global_routes[rt.routing_table].push(rt)
                end
              end
              return if global_routes.empty?
              ups = []
              downs = []
              global_routes.each do |rtable, rts|
                grts = IPAddress::summarize(rts.map{|i| i.dst_addr_or_tag})
                ups += grts.map do |route|
                  reject_route(route, find_metric(rts, route, rtable), rtable, 'add')
                end
                downs += grts.map do |route|
                  reject_route(route, find_metric(rts, route, rtable), rtable, 'del')
                end
              end
              blocks = ups
              result.add(RejectRoutes, Construqt::Util.render(binding, "interfaces_sh_envelop.erb"),
                         Construqt::Resources::Rights.root_0755,
                         'etc', 'network', "RejectRoutes-up.sh")
              blocks = downs
              result.add(RejectRoutes, Construqt::Util.render(binding, "interfaces_sh_envelop.erb"),
                         Construqt::Resources::Rights.root_0755,
                         'etc', 'network', "RejectRoutes-down.sh")
              # binding.pry
              up_downer = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::UpDowner::OncePerHost)
              up_downer.add(@host, Tastes::Entities::RejectRoutes.new)
            end
          end

          class Action
          end

          class Factory
            attr_reader :machine
            def start(service_factory)
              @machine ||= service_factory.machine
                .service_type(Service)
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
