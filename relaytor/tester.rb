
require 'ipaddr'
require 'socket'


SIOCGIFNAME=0x8910
SIOCGIFFLAGS=0x8913
SIOCGIFADDR=0x8915

IFF_BROADCAST=1<<1

sock = Socket.new(Socket::AF_INET, Socket::SOCK_DGRAM, 0)

class IfParameter
  attr_accessor :ifname, :idx, :addr
end
if_parameter = IfParameter.new
idx = 1
ret = 0
while (1)
  begin
    ifr = [ "", idx, "" ].pack("a16La20")
    ret = sock.ioctl(SIOCGIFNAME, ifr)
    ifname = ifr.unpack("a16").first
    puts ifname, ifname.class.name
    ifr = [ ifname, 0, "" ].pack("a16La20")
    sock.ioctl(SIOCGIFFLAGS, ifr)
    _, flags = ifr.unpack("a16S")
    puts "#{ifname}=>#{"%x"%flags} #{flags & IFF_BROADCAST}"
    if (flags & IFF_BROADCAST) != 0
      ifr = [ ifname, idx, "" ].pack("a16La20")
      sock.ioctl(SIOCGIFADDR, ifr)
      ifname, family, port, addr = ifr.unpack("a16SSa4")
      if_parameter.idx = idx
      #puts "XXXX#{ifr.inspect}->#{family.inspect}->#{addr.inspect}"
      if_parameter.ifname = ifname.unpack("Z16").first
      if_parameter.addr = IPAddr.ntop(addr)
      puts "FOUND:#{if_parameter.inspect}"
      break
    end
  rescue SystemCallError => e
    puts e
    break
  end
  idx += 1
end
sock.close
client_port = Random.rand(2**14) + 27395
relay_port = client_port + 1
server_port = client_port + 2
relaytor = "./relaytor -r #{"lo" || if_parameter.ifname}%#{relay_port}%#{if_parameter.addr}%#{server_port}%#{if_parameter.addr} &"
puts relaytor
system relaytor
loops=100000
#  linuxV4PacketSource.addRelay("eth0", 67,  "192.168.176.1", 67, "192.168.176.110");
ret = Process.fork
if ret.nil?
    sleep 1
    puts "client #{client_port}"
    sock = UDPSocket.new
    sock.bind("0.0.0.0", client_port)
    sock.connect(if_parameter.addr, relay_port)
    sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
    loops.times do |cnt|
      dhcp_request = Array.new(307).map{ 0 }
      dhcp_request[0] = 1
      [cnt + 0x12051968].pack("L").unpack("C*").each_with_index do |x, idx|
        dhcp_request[4+idx] = x
      end
      begin
        #packet = dhcp_request.pack("b%d"%dhcp_request.length)
        #puts "SEND #{dhcp_request.inspect}"
        sock.send(dhcp_request.map{|i| i.chr}.join(''), 0)
      rescue Exception => e
        p e
      end
      begin
        data, sockaddr = sock.recvfrom_nonblock(1024)
        if data.length != 307
          raise "Not the right length"
        end
        data = data.unpack("C%d"%data.length)
        if data[0] != 2
          raise "Not the right op code"
        end
        if data[3] != 3
          raise "Not the right hop count"
        end
        unless data[4..7].pack("C*").unpack("L").first == (0x12051968 + cnt)
          raise "Not the right xid #{cnt}"
        end
        unless if_parameter.addr == IPAddr.ntop(data[24..27].pack("C*"))
          raise "giaddr not set"
        end
        unless "20.21.22.23" == IPAddr.ntop(data[20..23].pack("C*")).to_s
          raise "siaddr not ok"
        end
      rescue IO::WaitReadable
        IO.select([sock])
        retry
      end
    end
  system "kill $(cat my.pid)"
  puts "Client Completed"
  Process.wait(pid)
else
  puts "server #{server_port}"
  sock = UDPSocket.new
  sock.bind("0.0.0.0", server_port)
  loops.times do |cnt|
    begin
      data, sockaddr = sock.recvfrom_nonblock(1024)
      if data.length != 307
        raise "Not the right length"
      end
      data = data.unpack("C%d"%data.length)
      if data[0] != 1
        raise "Not the right op code"
      end
      if data[0] != 1
        raise "Not the right hop count"
      end
      unless data[4..7].pack("C*").unpack("L").first == (0x12051968 + cnt)
        raise "Not the right xid #{cnt} #{data[4..7]}"
      end
      unless if_parameter.addr == IPAddr.ntop(data[24..27].pack("C*"))
        raise "giaddr not set"
      end
      data[0] = 2
      data[3] = 2
      data[12] = data[24]
      data[13] = data[25]
      data[14] = data[26]
      data[15] = data[27]
      data[20] = 20
      data[21] = 21
      data[22] = 22
      data[23] = 23
      sock.connect(if_parameter.addr.to_s, relay_port)
      sock.send(data.map{|i| i.chr}.join(''), 0)
    rescue IO::WaitReadable
      IO.select([sock])
      retry
    end
  end
  puts "Server Completed"
end

