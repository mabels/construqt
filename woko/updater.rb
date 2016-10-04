
def lxc_ls()
	`lxc-ls -f`.lines[1..-1].map do |line|
		line.split(/\s+/)
	end
end

def lxc_start
	lxc_ls.select{ |i| i[1] == "STOPPED" }.each{|i| `lxc-start -n '#{i[0]}'` }
	running = false
	while (!running) 
		sleep(1)
		lxc = lxc_ls
		res = lxc.select{ |i| i[1] == "RUNNING"}.select{ |i| i[4] != "-"}
		running = lxc.length == res.length
puts "#{running} #{res}"
	end
end
def lxc_stop
	lxc_ls.select{ |i| i[1] == "RUNNING" }.each{|i| `lxc-stop -n #{i[0]} &` }
	running = false
	while (!running) 
		sleep(1)
		lxc = lxc_ls
		running = lxc_ls.select{ |i| i[1] == "STOPPED" }.length == lxc.length
	end
end

def lxc_attach(name, cmd)
	`lxc-attach -n #{name} -- #{cmd}`
end

#lxc_start
#puts("all running");

lxc_ls.each do |i|
	IO.write("/var/lib/lxc/#{i[0]}/rootfs/updater.sh", <<SH)
#!/bin/sh
DEBIAN_FRONTEND=noninteractive
export DEBIAN_FRONTEND
apt-get update 
apt-get -q upgrade -fy 
touch /updater.sh.done
SH
	prefix=""
	prefix="/usr/bin/qemu-arm-static" if i[0].include?("-arm")
	IO.write("/root/#{i[0]}.at", "/usr/sbin/chroot /var/lib/lxc/#{i[0]}/rootfs #{prefix} /bin/sh /updater.sh > /root/#{i[0]}.at.out 2>&1")
	`at -f /root/#{i[0]}.at now`
#	puts i[0]
#	lxc_attach i[0], 'rm -f /updater.sh /updater.sh.done'
#	`(echo '#!/bin/sh' ; echo "apt-get update >> /tmp/out"; echo "apt-get -q upgrade -fy >> /tmp/out"; echo "touch /updater.sh.done") | lxc-attach -n #{i[0]} tee /updater.sh`
#	lxc_attach i[0], 'apt-get install -q -fy screen'
#	lxc_attach i[0], 'chmod 755 /updater.sh'
#	lxc_attach i[0], 'screen -dmS meno -s /updater.sh'
#	puts $?
end
#all_done = false
#while !all_done
#	lxc = lxc_ls
#	dones = lxc.map { |i| `lxc-attach -n #{i[0]} -- test -f /updater.sh.done`; $?.to_i }#.select{|i| i[1].to_i == 0}
#	all_done = dones.length == lxc.select{|i| i == 0}.length 
#	puts lxc.inspect
#	puts dones.join(":")
#	sleep(5)
#end

#lxc_stop
#puts("all stopped");

#lxc-ls`.each do |lxc|
#  495  for i in $(lxc-ls); do lxc-attach -n $i apt-get update; done
#  496  for i in $(lxc-ls); do lxc-attach -n $i apt-get upgrade; done
#  497  for i in $(lxc-ls); do lxc-attach -n $i apt-get -qy upgrade; done
#  498  for i in $(lxc-ls); do lxc-attach -n $i -- apt-get -qy upgrade; done
#  499  for i in $(lxc-ls); do lxc-attach -n $i -- apt-get -q upgrade -y; done
#  500  for i in $(lxc-ls); do lxc-attach -n $i -- apt-get  upgrade -qy; done
#  501  for i in $(lxc-ls); do lxc-attach -n $i -- apt-get -qq  upgrade -y; done
#  502  for i in $(lxc-ls); do lxc-attach -n $i -- apt-get -qq  upgrade -fy; done
#  503  for i in $(lxc-ls); do lxc-attach -n $i -- "nohup apt-get -qq  upgrade -fy &"; done
#  504  for i in $(lxc-ls); do lxc-attach -n $i -- apt-get -qq  upgrade -fy; done
#  505  ps -ax
#  506  for i in $(lxc-ls); do lxc-stop -n $i ; done
#  507  lxc-ls -f
