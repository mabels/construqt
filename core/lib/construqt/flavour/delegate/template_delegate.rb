module Construqt
  module Flavour
    module Delegate


      class TemplateDelegate
        include Delegate
        COMPONENT = Construqt::Resources::Component::UNREF
        def initialize(template)
          self.delegate = template
        end
      end
    end
  end
end
