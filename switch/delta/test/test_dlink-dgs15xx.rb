CONSTRUQT_PATH=ENV['CONSTRUQT_PATH']||'..'
["#{CONSTRUQT_PATH}/ipaddress/lib","#{CONSTRUQT_PATH}/construqt"].each{|path| $LOAD_PATH.unshift(path) }

require "test/unit"
require "construqt/construqt.rb"
require "switch-delta/test/test_ciscian.rb"

module Construqt
  module Flavour
    module Ciscian

      class TestDlinkDgs15xx < CiscianTestCase
        def test_vlan_name_changed
          old_config = <<-CONFIG
          vlan 110
          name v110
          exit
          CONFIG

          nu_config = <<-CONFIG
          vlan 110
          name newname
          exit
          CONFIG

          expected = <<-CONFIG
          vlan 110
          name newname
          exit
          CONFIG

          assert_equal_config(expected, create_delta_config("dlink-dgs15xx", old_config, nu_config))
        end

        def test_allowed_vlan_changed
          old_config = <<-CONFIG
          interface ethernet 1/0/1
          switchport trunk allowed vlan 100,101,102
          exit
          CONFIG

          nu_config = <<-CONFIG
          interface ethernet 1/0/1
          switchport trunk allowed vlan 99,100,102
          exit
          CONFIG

          expected = <<-CONFIG
          interface ethernet 1/0/1
          switchport trunk allowed vlan 99-100,102
          exit
          CONFIG

          assert_equal_config(expected, create_delta_config("dlink-dgs15xx", old_config, nu_config))
        end

        def test_remove_allowed_vlan
          old_config = <<-CONFIG
          interface ethernet 1/0/1
          switchport trunk allowed vlan 100,101,102
          exit
          CONFIG

          nu_config = <<-CONFIG
          interface ethernet 1/0/1
          no switchport trunk allowed vlan
          exit
          CONFIG

          expected = <<-CONFIG
          interface ethernet 1/0/1
          no switchport trunk allowed vlan
          exit
          CONFIG

          assert_equal_config(expected, create_delta_config("dlink-dgs15xx", old_config, nu_config))
        end

        def test_native_vlan_changed
          old_config = <<-CONFIG
          interface ethernet 1/0/1
          switchport trunk native vlan 100
          exit
          CONFIG

          nu_config = <<-CONFIG
          interface ethernet 1/0/1
          switchport trunk native vlan 101
          exit
          CONFIG

          expected = <<-CONFIG
          interface ethernet 1/0/1
          switchport trunk native vlan 101
          exit
          CONFIG

          assert_equal_config(expected, create_delta_config("dlink-dgs15xx", old_config, nu_config))
        end

        def test_no_changes1
          old_config = <<-CONFIG
          interface ethernet 1/0/1
          switchport trunk native vlan 100
          exit
          CONFIG

          nu_config = <<-CONFIG
          interface ethernet 1/0/1
          switchport trunk native vlan 100
          exit
          CONFIG

          expected = <<-CONFIG
          CONFIG

          assert_equal_config(expected, create_delta_config("dlink-dgs15xx", old_config, nu_config))
        end

        def test_hostname_changed
          old_config = <<-CONFIG
          interface vlan 995
          ip dhcp client hostname  old
          exit
          CONFIG

          nu_config = <<-CONFIG
          interface vlan 995
          ip dhcp client hostname  new
          exit
          CONFIG

          expected = <<-CONFIG
          interface vlan 995
          ip dhcp client hostname  new
          exit
          CONFIG

          assert_equal_config(expected, create_delta_config("dlink-dgs15xx", old_config, nu_config))
        end

        def test_interface_ranges
          old_config = <<-CONFIG
          interface ethernet 1/0/1
          switchport trunk allowed vlan 101,102
          exit
          CONFIG

          nu_config = <<-CONFIG
          interface ethernet 1/0/1-1/0/3
          switchport trunk allowed vlan 101,102
          exit
          CONFIG

          expected = <<-CONFIG
          interface ethernet 1/0/2
          switchport trunk allowed vlan 101-102
          exit
          interface ethernet 1/0/3
          switchport trunk allowed vlan 101-102
          exit
          CONFIG

          assert_equal_config(expected, create_delta_config("dlink-dgs15xx", old_config, nu_config))
        end

        def test_add_port_to_bond
          old_config = <<-CONFIG
          interface port-channel 13
          exit

          interface ethernet 1/0/1
          channel-group 13 mode active
          exit
          CONFIG

          nu_config = <<-CONFIG
          interface port-channel 13
          exit

          interface ethernet 1/0/1
          channel-group 13 mode active
          exit
          interface ethernet 1/0/2
          channel-group 13 mode active
          exit
          CONFIG

          expected = <<-CONFIG
          interface ethernet 1/0/2
          channel-group 13 mode active
          exit
          CONFIG

          assert_equal_config(expected, create_delta_config("dlink-dgs15xx", old_config, nu_config))
        end

        def test_change_bond
          old_config = <<-CONFIG
          interface port-channel 13
          exit

          interface ethernet 1/0/1
          channel-group 13 mode active
          exit
          CONFIG

          nu_config = <<-CONFIG
          interface port-channel 14
          exit

          interface ethernet 1/0/1
          channel-group 14 mode active
          exit
          CONFIG

          expected = <<-CONFIG
          interface ethernet 1/0/1
          channel-group 14 mode active
          exit
          no interface port-channel 13
          interface port-channel 14
          exit
          CONFIG

          assert_equal_config(expected, create_delta_config("dlink-dgs15xx", old_config, nu_config))
        end

        def test_ip_routes
          old_config = <<-CONFIG
          ip route 20.0.0.0 255.0.0.0 10.1.1.253
          ip route 20.0.0.0 255.0.0.0 10.1.1.252
          ip route 20.0.0.0 255.0.0.0 10.1.1.251
          ip route 20.0.0.0 255.0.0.0 10.1.1.250
          CONFIG

          nu_config = <<-CONFIG
          ip route 20.0.0.0 255.0.0.0 10.1.1.254
          ip route 20.0.0.0 255.0.0.0 10.1.1.253
          ip route 20.0.0.0 255.0.0.0 10.1.1.252
          ip route 20.0.0.0 255.0.0.0 10.1.1.214
          ip route 20.0.0.0 255.0.0.0 10.1.1.215
          CONFIG

          expected = <<-CONFIG
          no ip route 20.0.0.0 255.0.0.0 10.1.1.251
          no ip route 20.0.0.0 255.0.0.0 10.1.1.250
          ip route 20.0.0.0 255.0.0.0 10.1.1.254
          ip route 20.0.0.0 255.0.0.0 10.1.1.214
          ip route 20.0.0.0 255.0.0.0 10.1.1.215
          CONFIG

          assert_equal_config(expected, create_delta_config("dlink-dgs15xx", old_config, nu_config))
        end

      end
    end
  end
end
