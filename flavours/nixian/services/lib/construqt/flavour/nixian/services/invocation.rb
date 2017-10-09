module Construqt
  module Flavour
    module Nixian
      module Services
        module Invocation
          class Service
            attr_accessor :implementation
            def initialize(impl = nil)
              self.implementation = impl
            end
          end

          class OncePerHost
            attr_reader :host, :service
            def initialize
            end

            def activate(context)
              @context = context
            end

            def attach_host(host)
              @host = host
            end

            def add_service(service)
              @service = service
            end

            def build_config_host
              host.region.hosts.get_hosts.select {|h| host.eq(h.mother) }.each do |d_host|
                # binding.pry
                invocation = d_host.result_types.result_types[Construqt::Flavour::Nixian::Services::Invocation::OncePerHost]
                next unless invocation
                next unless invocation.instance.service
                next unless invocation.instance.service.implementation
                invocation.instance.service.implementation.invocation_build_config_host(host, @context)
                # d_host.services.by_type_of(Service).each do |d_srv|
                #   render(result, d_host, d_srv)
                # end
              end
            end

            def commit
              host.region.hosts.get_hosts.select {|h| host.eq(h.mother) }.each do |d_host|
                # binding.pry
                invocation = d_host.result_types.result_types[Construqt::Flavour::Nixian::Services::Invocation::OncePerHost]
                next unless invocation
                next unless invocation.instance.service
                next unless invocation.instance.service.implementation
                next unless invocation.instance.service.implementation.respond_to?(:invocation_commit)
                invocation.instance.service.implementation.invocation_commit(host, @context)
                # d_host.services.by_type_of(Service).each do |d_srv|
                #   render(result, d_host, d_srv)
                # end
              end
            end

          end

          class Action
            def initialize(host, service)
              @host = host
              @service = service
              service.implementation && service.implementation.attach_host(host)
            end

            def activate(ctx)
              @context = ctx
              oph = @context.find_instances_from_type(OncePerHost)
              oph.add_service(@service)
            end
          end

          class Factory
            attr_reader :machine
            def start(service_factory)
              @machine ||= service_factory.machine
                .service_type(Service)
                .result_type(OncePerHost)
                .depend(Result::Service)
            end

            def produce(host, srv_inst, ret)
              Action.new(host, srv_inst)
            end
          end


        end
      end
    end
  end
end
