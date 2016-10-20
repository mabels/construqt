

module Construqt
    class Hosts
      class Docker
        include Construqt::Util::Chainable
        chainable_attr :image, "ubuntu:16.04"
        chainable_attr :app_start_script, ""
      end
    end
end
