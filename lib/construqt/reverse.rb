require 'rubygems'
require 'linux/ip/addr'
require 'linux/ip/route'
CONSTRUQT_PATH=ENV['CONSTRUQT_PATH']||'..'
["#{CONSTRUQT_PATH}/construqt/lib","#{CONSTRUQT_PATH}/ipaddress/lib"].each{|path| $LOAD_PATH.unshift(path) }
require 'construqt'

# ruby lib/construqt/reverse.rb addr ~/addrs routes ~/routes
if cp = ARGV.index("addr")
  addr = Linux::Ip::Addr.parse_from_lines(IO.read(ARGV[cp+1]).lines)
else
  addr = Linux::Ip::Addr.parse
end
if cp = ARGV.index("routes")
  routes = Linux::Ip::Route.parse_from_lines(IO.read(ARGV[cp+1]).lines)
else
  routes = Linux::Ip::Route.parse
end

def render_iface(ifaces, routes)
  ifaces.interfaces.map do |iface|
    next [] if iface.name == 'lo'
    next [] if iface.ips.empty?
    out = <<RUBY
  region.interfaces.add_device(host, "#{iface.name}", "mtu" => 1500,
      'mac_address' => #{iface.mac_address},
      'address' => region.network.addresses.
#{Construqt::Util.indent((
    iface.ips.map{|i| "add_ip('#{i.to_s}')" }+
    (routes.interfaces[iface.name] ? routes.interfaces[iface.name].select{|i| i.kind_of?(Linux::Ip::Route::IpRoute::ViaRoute) }.map{|i| "add_route('#{i.dst.to_s}', '#{i.via.to_s}')" } : [])).join(".\n"), 22)})
RUBY
  end.join("\n")
end

puts <<RUBY
region.hosts.add("REVERSE-HOST", "flavour" => "ubuntu") do |host|
  region.interfaces.add_device(host, "lo", "mtu" => "1500", :description=>"loopback",
                                    "address" => region.network.addresses.add_ip(Construqt::Addresses::LOOOPBACK))

#{render_iface(addr, routes)}

end
RUBY
