
# require 'construqt/flavours/nixian/tastes/entities'

module Construqt
  module Flavour
    module Nixian
      module Services
        module UpDowner
          class TasteDispatch
            include Construqt::Util::Chainable
            chainable_attr_value :taste
            chainable_attr_value :actors
          end

          class Updown
            include Construqt::Util::Chainable
            chainable_attr_value :iface
            chainable_attr_value :ud
            chainable_attr_value :taste_dispatch
            def commit
              get_taste_dispatch.each do |td|
                # binding.pry
                td.get_actors.each do |ac|
                  if ac.respond_to?(:commit)
                    #binding.pry
                    ac.commit(td.get_taste, get_iface, get_ud)
                  end
                end

                if td.get_taste.respond_to?(:commit)
                  td.get_taste.commit(get_iface, get_ud)
                end
              end
            end
          end

          class Service

            attr_reader :tastes, :result
            def initialize
              @tastes = []
              @result = nil
            end

            def taste(taste)
              @tastes.push(taste)
              #taste.result = @result
              self
            end
          end

          class OncePerHost
            # attr_reader :result_types
            attr_reader :host
            def initialize # (result_types, host)
              #@result_types = result_types
              #@host = host
              @updos = []
            end

            def activate(rt)
              st = rt.find_by_service_type(Construqt::Flavour::Nixian::Services::UpDowner::Service)
              @updowner = st.service_producers.first.srv_inst
              @updowner.tastes.each do |t|
                t.activate(rt)
              end
            end

            def attach_host(host)
             @host = host
            end

            #def attach_interface(interface)
            #  @interface = interface
            #end

            #def attach_result(result)
            #end

            def produce(_, __, ___)
              binding.pry
            end

            #def attach_service(service)
            #  # binding.pry
            #  throw "double attach of service not supported" if @service
            #  @service = service
            #end

            def start()
              # binding.pry
            end

            def add(iface, ud)
              # binding.pry
              # @updos.push(ud)
              taste_dispatch = []
              @updowner.tastes.each do |t|
                dispatches = t.dispatches(ud.class.name)
                throw "unknown dispatch for #{t.class.name} on #{ud.class.name}" unless dispatches
                taste_dispatch.push TasteDispatch.new.taste(t).actors(dispatches)
                dispatches.each do |d|
                  if d.respond_to?(:on_add)
                    d.on_add(self, t, iface, ud)
                  end
                end
              end
              @updos.push(Updown.new.iface(iface).ud(ud).taste_dispatch(taste_dispatch))
              self
            end

            def commit
              # binding.pry
              @updos.each do |updo|
                updo.commit
              end

              # @updos.each do |ud|
              #   Construqt.logger.info "#{ud.class.name.split("::").last}=>#{@tastes.map{|f| f.class.name.split("::").last}.join(",")}"
              # end

              # binding.pry
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
            end

            def produce(host, srv_inst, ret)
              Action.new
            end
          end

          class Activator
            include Construqt::Util::Chainable
            chainable_attr_value :entity
            def initialize
              @impls = {}
            end
            def add(taste, impl)
              @impls[taste] = impl
              self
            end
            def actions
              {
                Construqt::Flavour::Nixian::Services::UpDowner::Service => lambda do |oph|
                  oph.tastes.each do |taste|
                    impl = @impls[taste.class]
                    impl && taste.add(get_entity, impl)
                  end
                end
              }
            end
          end
        end
      end
    end
  end
end
