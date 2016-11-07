

module Construqt
    class Hosts
      class Docker
        include Construqt::Util::Chainable
        chainable_attr :image, "ubuntu:16.04"
        chainable_attr :app_start_script, ""
        chainable_attr :pkt_man, :apt

        def is_apt
          get_pkt_man == :apt
        end

        def is_apk
          get_pkt_man == :apk
        end
      end
    end
end
