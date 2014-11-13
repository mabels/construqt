require_relative("configmodel.rb")
require_relative("flavour.rb")
require_relative("flavour_#{ARGV[0]}.rb")

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
