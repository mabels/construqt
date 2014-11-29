

id = Construqt::HostId.create do |block|
  assert_eq(block.interfaces.length, 0)
end

assert_eq(id.first_ipv6!, nil)
assert_eq(id.first_ipv4!, nil)

begin
  id.first_ipv4
  assert("should not happend")
raise
end

begin
  id.first_ipv6
  assert("should not happend")
raise
end

iface = XXXXX
id = Construqt::HostId.create do |block|
  assert_eq(block.interfaces.length, 0)
  block.interfaces << iface
end

assert_eq(id.first_ipv6!, iface.first_ipv6)
assert_eq(id.first_ipv4!, iface.first_ipv4)

assert_eq(id.first_ipv6, iface.first_ipv6)
assert_eq(id.first_ipv4, iface.first_ipv4)
