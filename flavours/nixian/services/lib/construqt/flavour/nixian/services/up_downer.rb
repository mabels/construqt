
# require 'construqt/flavours/nixian/tastes/entities'

module Construqt
  module Flavour
    module Nixian
      module Services
        class UpDowner
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
                  td.get_actors.each do |ac|
                    if ac.respond_to?(:commit)
                      ac.commit(td.taste, get_iface, get_ud)
                    end
                  end
                end
              end
            end

            attr_reader :tastes, :result
            def initialize
              @tastes = []
              @result = nil
            end
            # def attach_result(result)
            #   @result = result
            #   self
            # end


            # def request_tastes_from(srv)
            #   @tastes.each do |taste|
            #     taste.register_srv(srv.entities_for_taste(taste))
            #   end
            # end

            def taste(taste)
              @tastes.push(taste)
              #taste.result = @result
              self
            end




            class UpDownerOncePerHost
              # attr_reader :result_types
              def initialize # (result_types, host)
                #@result_types = result_types
                #@host = host
                @updos = []
              end

              def activate(rt)
                st = rt.find_by_service_type(Construqt::Flavour::Nixian::Services::UpDowner)
                @updowner = st.service_producers.first.srv_inst
                @updowner.tastes.each do |t|
                  t.activate(rt)
                end
              end
              #def attach_host(host)
              #  @host = host
              #end
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
                    if d.respond_to?(:onAdd)
                      d.onAdd(self, t, iface, ud)
                    end
                  end
                end
                @updos.push(Updown.new.iface(iface).ud(ud).taste_dispatch(taste_dispatch))
                self
              end
              def commit
                @updos.each do |updo|
                  updo.commit
                end
                # @updos.each do |ud|
                #   Construqt.logger.info "#{ud.class.name.split("::").last}=>#{@tastes.map{|f| f.class.name.split("::").last}.join(",")}"
                # end
                # binding.pry
              end

            end

            class UpdownAction
            end

            class Factory
              attr_reader :machine
              def initialize(service_factory)
                @machine = service_factory.machine
                  .service_type(UpDowner)
                  .result_type(UpDownerOncePerHost)
                  .depend(Result)
              end
              def produce(host, srv_inst, ret)
                UpdownAction.new
              end

            end
          end
        end
      end
    end
end
