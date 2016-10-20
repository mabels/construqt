module Construqt
  module Flavour
    module Delegate

      class DeviceDelegate
        include Delegate
        COMPONENT = Construqt::Resources::Component::UNREF
        def initialize(device)
          self.delegate = device
        end

        def interfaces
          self.delegate.interfaces
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
