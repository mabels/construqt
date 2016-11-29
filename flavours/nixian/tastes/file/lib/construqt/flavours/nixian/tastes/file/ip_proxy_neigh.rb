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
