module Construqt
  module SwitchDelta

    class DeltaCommandRenderer
      def buildConfig(oldSwitchConfig, newSwitchConfig, delta)
        throw "this method must be implemented in specific flavour"
      end
    end

  end
end
