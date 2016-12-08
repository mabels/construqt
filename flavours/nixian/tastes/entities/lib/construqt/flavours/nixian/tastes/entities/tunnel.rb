

module Construqt
  module Flavour
    module Nixian
      module Tastes
        module Entities
          class Tunnel
            attr_reader :cfg, :local, :remote
            def initialize(cfg, local, remote)
              @cfg = cfg
              @local = local
              @remote = remote
            end
          end
          add(Tunnel)
        end
      end
    end
  end
end
