
Construqt::Bgps.add_as(93925993, "redistribute-connected" => true,
                                 "redistribute-static" => true,
                                 "redistribute-other-bgp" => true,
                                 "description" => "test-93925993")

Construqt::Bgps.add_as(73925993, "redistribute-connected" => true,
                                 "redistribute-static" => true,
                                 "redistribute-other-bgp" => true,
                                 "description" => "test-73925993")

Construqt::Bgps.connection("name_it",
        "password" => "geheim",
        "left" => {
          "as" => Construqt::Bgps::find_as(93925993),
          "my" => ipsec.left.interface,
          "filter" => { "in" => Construqt::Bgps.find_filter('mgmt_net_in'), "out" => Construqt::Bgps.find_filter('mgmt_net_out') },
        },
        "right" => {
          "as" => Construqt::Bgps::find_as(73925993),
          "my" => ipsec.right.interface,
          "filter" => { "in" => Construqt::Bgps.find_filter('mgmt_net_in'), "out" => Construqt::Bgps.find_filter('mgmt_net_out') },
        }
    )
