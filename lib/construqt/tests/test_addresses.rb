
addresses = Construqt::Addresses.new(7)

assert_eq(addresses.network, 7)

adr = addresses.create

assert_eq(addresses.all.length, 0)

adr.set_name("jojo")
assert_eq(adr.name, "jojo")

adr.name = "jojojo"
assert_eq(adr.name, "jojojo")

adr.add_ip("192.168.0.1")
assert_eq(adr.all.length, 1)
assert_eq(adr.v4s.length, 1)
assert_eq(adr.v6s.length, 0)

adr.add_ip("192.168.0.2")
assert_eq(adr.all.length, 2)
assert_eq(adr.v4s.length, 2)
assert_eq(adr.v6s.length, 0)

adr.add_ip("2000::/27")
assert_eq(adr.all.length, 3)
assert_eq(adr.v4s.length, 2)
assert_eq(adr.v6s.length, 1)

adr.add_ip("2001::/27")
assert_eq(adr.all.length, 4)
assert_eq(adr.v4s.length, 2)
assert_eq(adr.v6s.length, 2)

assert_eq(adr.first_ipv4, "192.168.0.1")
assert_eq(adr.first_ipv6, "2001::/27")

assert_eq(adr.dhcpv4?, false)
adr.add_ip(DHCPV4)
assert_eq(adr.dhcpv4?, true)

assert_eq(adr.dhcpv6?, false)
adr.add_ip(DHCPV6)
assert_eq(adr.dhcpv6?, true)

assert_eq(adr.loopback?, false)
adr.add_ip(LOOPBACK)
assert_eq(adr.loopback?, true)

