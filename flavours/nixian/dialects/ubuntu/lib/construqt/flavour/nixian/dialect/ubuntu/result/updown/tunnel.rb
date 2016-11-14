

module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result
            module UpDown
              class Tunnel
                attr_reader :cfg, :local, :remote
                def initialize(cfg, local, remote)
                  @cfg = cfg
                  @local = local
                  @remote = remote
                end
              end
            end
          end
        end
      end
    end
  end
end
