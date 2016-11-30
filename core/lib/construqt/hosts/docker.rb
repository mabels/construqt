

module Construqt
    class Hosts
      class Docker
        include Construqt::Util::Chainable
        chainable_attr :image, "ubuntu:16.04"
        chainable_attr :app_start_script, ""
        chainable_attr :pkt_man, :apt

        def initialize
          @packages = []
        end
        def package(pkg)
          @packages.push(pkg)
          self
        end
        def get_packages
          @packages
        end
        def map(h, d)
          @maps ||= {}
          @maps[h] = d
          self
        end
        def get_maps
          @maps || {}
        end

        def privileged
          @privileged = true
          self
        end


        def get_privileged
          @privileged || false
        end

        def is_apt
          get_pkt_man == :apt
        end

        def is_apk
          get_pkt_man == :apk
        end
      end
    end
end
