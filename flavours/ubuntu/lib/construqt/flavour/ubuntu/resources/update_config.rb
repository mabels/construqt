#!/usr/bin/env ruby
#
require 'rubygems'

require 'linux/lxc'

config_fname = ARGV.first
updated_list = ARGV[1]
key = ARGV[2]
value = ARGV.last

#puts "config_fname = #{ARGV.first} updated_list = #{ARGV[1]} key = #{ARGV[2]} value = #{ARGV.last}"

lxc = Linux::Lxc.parse(config_fname)

found = lxc.get(key)
if found.nil? or found.empty?
  lxc.add(key, value)
  found = lxc.get(key)
end
found.each { |line| line.value = value }
# store copy to allow git handling
lxc.index.files.values.each do |file|
  file.real_fname = File.join('/',File.dirname(file.file),".#{File.basename(file.file)}.import")
end
lxc.write
out = lxc.index.files.values.map{|i| i.file }.join("\n")
IO.write(updated_list, out+(lxc.index.files.values.length>0 ? "\n":""))
