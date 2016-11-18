
require 'construqt/flavours/nixian/tastes/entities'

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result
            class UpDowner
              attr_reader :tastes
              def initialize(result)
                @result = result
                # @updos = []
                @tastes = []
              end
              def add(iface, ud)
                # @updos.push(ud)
                @tastes.each do |t|
                  dispatch = t.dispatch(ud.class.name)
                  throw "unknown dispatch for #{t.class.name} on #{ud.class.name}" unless dispatch
                  dispatch.call(iface, ud)
                end
                self
              end

              def request_tastes_from(srv)
                @tastes.each do |taste|
                  taste.register_srv(srv.entities_for_taste(taste))
                end
              end

              def taste(taste)
                @tastes.push(taste)
                taste.result = @result
                self
              end

              def commit
                @tastes.each do |ud|
                  ud.commit
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
