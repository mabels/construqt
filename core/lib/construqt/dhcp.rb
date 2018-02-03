module Construqt
  class Dhcp
    include Construqt::Util::Chainable
    chainable_attr_value :start
    chainable_attr_value :end
    chainable_attr_value :domain
  end
end
