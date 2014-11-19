
Construct::Bgps.add_as(93925993, "redistribute-connected" => true,
                                 "redistribute-static" => true,
                                 "redistribute-other-bgp" => true,
                                 "description" => "test-93925993")

Construct::Bgps.add_as(73925993, "redistribute-connected" => true,
                                 "redistribute-static" => true,
                                 "redistribute-other-bgp" => true,
                                 "description" => "test-73925993")

Construct::Bgps.connection("name_it",
        "password" => "geheim",
        "left" => {
          "as" => Construct::Bgps::find_as(93925993),
          "my" => ipsec.left.interface,
          "filter" => { "in" => Construct::Bgps.find_filter('mgmt_net_in'), "out" => Construct::Bgps.find_filter('mgmt_net_out') },
        },
        "right" => {
          "as" => Construct::Bgps::find_as(73925993),
          "my" => ipsec.right.interface,
          "filter" => { "in" => Construct::Bgps.find_filter('mgmt_net_in'), "out" => Construct::Bgps.find_filter('mgmt_net_out') },
        }
    )
