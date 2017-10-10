module Construqt
  module Flavour
    module Delegate

      class DeviceDelegate
        include Delegate
        include InterfaceNode
        COMPONENT = Construqt::Resources::Component::UNREF
        def initialize(device)
          self.delegate = device
          self.init_node()
        end

        def _ident
          #binding.pry
          #Construqt.logger.debug "DeviceDelegate::_ident:#{attached.delegate.name}"
          "Device_#{delegate.host.name}_#{self.name}"
        end

        

        # def inspect
        #   "#<#{self.class.name}:#{object_id} ident=#{_ident}>"
        # end
      end
    end
  end
end
