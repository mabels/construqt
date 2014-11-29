CONSTRUQT_PATH=ENV['CONSTRUQT_PATH']||'..'
["#{CONSTRUQT_PATH}/ipaddress/lib","#{CONSTRUQT_PATH}/construqt"].each{|path| $LOAD_PATH.unshift(path) }

require("construqt/construqt.rb")
require("construqt/flavour/ciscian/ciscian.rb")

require("switch-delta/configmodel.rb")
require("switch-delta/flavour.rb")
require("switch-delta/flavour_#{ARGV[0]}.rb")

module Construqt
  module SwitchDelta

    #remove flavour argument
    flavour = ARGV.shift
    parser = Flavour.parsers[flavour].new
    renderer = Flavour.renderers[flavour].new

    swap = ARGV[0] == "swap"
    if (swap)
      ARGV.shift
    end

    oldConfig = []
    while ( line = $stdin.gets )
      oldConfig << line.chomp
    end
    oldSwitchConfig = parser.parse(oldConfig)

    newConfig = []
    while ( line = ARGF.gets )
      newConfig << line
    end
    newSwitchConfig = parser.parse(newConfig)

    if (swap)
      temp=newSwitchConfig
      newSwitchConfig=oldSwitchConfig
      oldSwitchConfig=temp
    end

    delta = newSwitchConfig.compare(oldSwitchConfig)

    puts renderer.buildConfig(oldSwitchConfig, newSwitchConfig, delta)

  end
end
