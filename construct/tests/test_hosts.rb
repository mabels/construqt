
hosts = Hosts.new(19)

assert_eq(hosts.region, 19)

hosts.set_default_password("9339")
assert_eq(hosts.default_password, "9339")

assert_eq(hosts.get_hosts.length, 0)

begin
  hosts.add("test", "lutz" => "fuchs") do |host|
  end
end

begin
  hosts.add("test", "lutz" => "fuchs") do |host|
  end
  assert("Should not happend")
raise
end


