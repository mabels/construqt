
require 'construqt/flavours/nixian/tastes/entities'

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result
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
                  class UpDowner
              attr_reader :tastes
              def initialize(result)
                @result = result
                @updos = []
                @tastes = []
              end
              def add(iface, ud)
                # @updos.push(ud)
                taste_dispatch = []
                @tastes.each do |t|
                  dispatches = t.dispatches(ud.class.name)
                  throw "unknown dispatch for #{t.class.name} on #{ud.class.name}" unless dispatches
                  taste_dispatch.push TasteDispatch.new.taste(t).actors(dispatches)
                  dispatches.each do |d|
                    if d.respond_to?(:onAdd)
                      d.onAdd(self, iface, ud)
                    end
                  end
                end
                @updos.push(Updown.new.iface(iface).ud(ud).taste_dispatch(taste_dispatch))
                self
              end

              # def request_tastes_from(srv)
              #   @tastes.each do |taste|
              #     taste.register_srv(srv.entities_for_taste(taste))
              #   end
              # end

              def taste(taste)
                @tastes.push(taste)
                taste.result = @result
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
          end
        end
      end
    end
  end
end
