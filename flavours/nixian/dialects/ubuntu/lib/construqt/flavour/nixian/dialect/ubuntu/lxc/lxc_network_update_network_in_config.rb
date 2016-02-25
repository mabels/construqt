#!/usr/bin/env ruby
#
require 'rubygems'

require 'linux/lxc'

config_fname = ARGV.first
network_config_fname = ARGV[1]
updated_list = ARGV[2]

lxc = Linux::Lxc.parse(config_fname)

lxc.get("lxc.network").comment!
found = lxc.get("lxc.include").select do |lxc_incl|
  File.expand_path(lxc_incl.value.file) == File.expand_path(network_config_fname)
end
if found.empty?
  network_config = Linux::Lxc.parse(network_config_fname)
  lxc.add("lxc.include", network_config)
else
  # remove tail of found array
  # or leave just one
  found[1..-1].each do |line|
    line.lxc.lines.remove(line)
  end
end
found = lxc.get("lxc.start.auto")
if found.nil? or found.empty?
  lxc.add('lxc.start.auto', '1')
  found = lxc.get("lxc.start.auto")
end
found.each { |line| line.value = '1' }
# store copy to allow git handling
lxc.index.files.values.each do |file|
  file.real_fname = File.join('/',File.dirname(file.file),".#{File.basename(file.file)}.import")
end
lxc.write
out = lxc.index.files.values.select do |i|
  File.expand_path(i.file) != File.expand_path(network_config_fname)
end.map{|i| i.file }.join("\n")
IO.write(updated_list, out+(out.length>0 ? "\n":""))
