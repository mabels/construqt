
module Construqt
    class Hosts
      class Lxc
        include Construqt::Util::Chainable

        chainable_attr :recreate
        chainable_attr :restart
        chainable_attr :upgrade
        chainable_attr :update
        #chainable_attr :template
        chainable_attr :killstop
        chainable_attr :aa_profile_unconfined

        chainable_attr_value :release
        chainable_attr_value :template

      end
    end
end
