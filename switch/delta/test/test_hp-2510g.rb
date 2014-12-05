CONSTRUQT_PATH=ENV['CONSTRUQT_PATH']||'.'
["#{CONSTRUQT_PATH}/construqt/lib"].each{|path| $LOAD_PATH.unshift(path) }

require "test/unit"
require "construqt"
require_relative "test_ciscian.rb"

module Construqt
  module Flavour
    module Ciscian

      class TestHp2510g < CiscianTestCase
        def test_vlan_name_changed
          old_config = <<-CONFIG
          vlan 110
          name "v110"
          exit
          CONFIG

          nu_config = <<-CONFIG
          vlan 110
          name "newname"
          exit
          CONFIG

          expected = <<-CONFIG
          vlan 110
          name "newname"
          exit
          CONFIG

          assert_equal_config(expected, create_delta_config("hp-2510g", old_config, nu_config))
        end

        def test_tagged_vlan_changed
          old_config = <<-CONFIG
          vlan 100
          tagged 1
          exit
          vlan 101
          tagged 1
          exit
          vlan 102
          tagged 1
          exit
          CONFIG

          nu_config = <<-CONFIG
          vlan 99
          tagged 1
          exit
          vlan 100
          tagged 1
          exit
          vlan 102
          tagged 1
          exit
          CONFIG

          expected = <<-CONFIG
          no vlan 101
          vlan 99
          tagged 1
          exit
          CONFIG

          assert_equal_config(expected, create_delta_config("hp-2510g", old_config, nu_config))
        end

        def test_untagged_vlan_changed
          old_config = <<-CONFIG
          vlan 100
          untagged 1
          exit
          CONFIG

          nu_config = <<-CONFIG
          vlan 101
          untagged 1
          exit
          CONFIG

          expected = <<-CONFIG
          no vlan 100
          vlan 101
          untagged 1
          exit
          CONFIG

          assert_equal_config(expected, create_delta_config("hp-2510g", old_config, nu_config))
        end

        def test_no_changes1
          old_config = <<-CONFIG
          vlan 100
          untagged 1
          exit
          CONFIG

          nu_config = <<-CONFIG
          vlan 100
          untagged 1
          exit
          CONFIG

          expected = <<-CONFIG
          CONFIG

          assert_equal_config(expected, create_delta_config("hp-2510g", old_config, nu_config))
        end

        def test_hostname_changed
          old_config = <<-CONFIG
          hostname "ProCurve Switch 2510G-48"
          CONFIG

          nu_config = <<-CONFIG
          hostname "Neu"
          CONFIG

          expected = <<-CONFIG
          hostname "Neu"
          CONFIG

          assert_equal_config(expected, create_delta_config("hp-2510g", old_config, nu_config))
        end

        def test_interface_ranges1
          old_config = <<-CONFIG
          vlan 101-102
          tagged 1
          exit
          CONFIG

          nu_config = <<-CONFIG
          vlan 101-102
          tagged 1-3
          exit
          CONFIG

          expected = <<-CONFIG
          vlan 101
          tagged 2-3
          exit
          vlan 102
          tagged 2-3
          exit
          CONFIG

          assert_equal_config(expected, create_delta_config("hp-2510g", old_config, nu_config))
        end

        def test_interface_ranges2
          old_config = <<-CONFIG
          vlan 101-102
          tagged 1
          exit
          CONFIG

          nu_config = <<-CONFIG
          vlan 101-102
          tagged 2-3
          exit
          CONFIG

          expected = <<-CONFIG
          vlan 101
          tagged 2-3
          no tagged 1
          exit
          vlan 102
          tagged 2-3
          no tagged 1
          exit
          CONFIG

          assert_equal_config(expected, create_delta_config("hp-2510g", old_config, nu_config))
        end

        def test_add_port_to_bond
          old_config = <<-CONFIG
          trunk 1 Trk13 Trunk
          CONFIG

          nu_config = <<-CONFIG
          trunk 1-2 Trk13 Trunk
          CONFIG

          expected = <<-CONFIG
          trunk 2 Trk13 Trunk
          CONFIG

          assert_equal_config(expected, create_delta_config("hp-2510g", old_config, nu_config))
        end

        def test_change_bond
          old_config = <<-CONFIG
          trunk 1 Trk13 Trunk
          CONFIG

          nu_config = <<-CONFIG
          trunk 1 Trk14 Trunk
          CONFIG

          expected = <<-CONFIG
          no trunk 1
          trunk 1 Trk14 Trunk
          CONFIG

          assert_equal_config(expected, create_delta_config("hp-2510g", old_config, nu_config))
        end

      end
    end
  end
end
