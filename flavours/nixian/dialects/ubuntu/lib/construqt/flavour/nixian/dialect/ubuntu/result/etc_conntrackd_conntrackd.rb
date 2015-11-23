module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result

            class EtcConntrackdConntrackd
              def initialize(result)
                @result = result
                @others = []
              end

              class Other
                attr_accessor :ifname, :my_ip, :other_ip
              end

              def add(ifname, my_ip, other_ip)
                other = Other.new
                other.ifname = ifname
                other.my_ip = my_ip
                other.other_ip = other_ip
                @others << other
              end

              def commit
                return '' if @others.empty?
                out = [<<CONNTRACKD]
General {
HashSize 32768
HashLimit 524288
Syslog on
LockFile /var/lock/conntrackd.lock
UNIX {
Path /var/run/conntrackd.sock
Backlog 20
}
SocketBufferSize 262142
SocketBufferSizeMaxGrown 655355
Filter {
Protocol Accept {
TCP
}
Address Ignore {
IPv4_address 127.0.0.1 # loopback
}
}
}
Sync {
Mode FTFW {
DisableExternalCache Off
CommitTimeout 1800
PurgeTimeout 5
}
CONNTRACKD
                @others.each do |other|
                  out.push(<<OTHER)
UDP Default {
    IPv4_address #{other.my_ip}
    IPv4_Destination_Address #{other.other_ip}
    Port 3780
    Interface #{other.ifname}
    SndSocketBuffer 24985600
    RcvSocketBuffer 24985600
    Checksum on
}
OTHER
                end

                out.push("}")
                out.join("\n")
              end
            end
          end
        end
      end
    end
  end
end
