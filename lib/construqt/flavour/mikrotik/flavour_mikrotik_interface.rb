module Construqt
  module Flavour
    module Mikrotik

      class Interface

        def self.render_ip(host, iface, ip)
          cfg = {
            "address" => ip,
            "interface" => iface.name
          }
          if ip.ipv6?
            default = {
              "address" => Schema.addrprefix.required,
              "interface" => Schema.identifier.required,
              "advertise" => Schema.boolean.default(false),
              "comment" => Schema.string.required.key
            }
            cfg['comment'] = "#{cfg['interface']}-#{cfg['address']}-CONSTRUQT"
            #puts ">>>>>>>> #{cfg.inspect}"
            host.result.render_mikrotik(default, cfg, "ipv6", "address")
          else
            default = {
              "address" => Schema.addrprefix.required,
              "interface" => Schema.identifier.required,
              "comment" => Schema.string.required.key
            }
            cfg['comment'] = "#{cfg['interface']}-#{cfg['address']}-CONSTRUQT"
            host.result.render_mikrotik(default, cfg, "ip", "address")
          end
        end

        def self.render_route(host, iface, rt)
          throw "dst via mismatch #{rt}" if rt.type.nil? and !(rt.dst.ipv6? == rt.via.ipv6? or rt.dst.ipv4? == rt.via.ipv4?)
          cfg = {
            "dst-address" => rt.dst,
            "gateway" => rt.via,
          }
          if rt.type.nil?
            cfg['gateway'] = rt.via
          else
            cfg['type'] = rt.type
          end

          cfg['distance'] = rt.metric if rt.metric

          cfg['routing-mark'] = rt.routing_table if rt.routing_table

          default = {
            "dst-address" => Schema.network.required.key(0),
            "gateway" => Schema.address,
            "type" => Schema.identifier,
            "distance" => Schema.int,
            "comment" => Schema.string.required.key(1),
            "routing-mark" => Schema.identifier
          }
          cfg['comment'] = "#{cfg['dst-address']} via #{cfg['gateway']} CONSTRUQT"
          if rt.dst.ipv6?
            host.result.render_mikrotik(default, cfg, "ipv6", "route")
          else
            host.result.render_mikrotik(default, cfg, "ip", "route")
          end
        end

        def self.checkIpv6Adresses(iface, ip=nil)
          ips = ip.nil? ? iface.address.ips : [ip]
          ips.each do |_ip|
            throw "ipv6 addresses are not supported for firewall mangle action=mark-routing: interface-name=#{iface.name}" if _ip.ipv6?
          end
        end

        def self.render_firewall_mangle_in_interface(host, iface)
          checkIpv6Adresses(iface)

          cfg = {
            "in-interface" => iface.name,
            "new-routing-mark" => iface.routing_table,
            "chain" => "prerouting",
            "action" => "mark-routing"
          }
          cfg['comment'] = "tag interface #{cfg['in-interface']} with routing-mark #{cfg['new-routing-mark']} CONSTRUQT"

          default = {
            "chain" => Schema.identifier.required,
            "action" => Schema.identifier.required,
            "new-routing-mark" => Schema.identifier.required,
            "in-interface" => Schema.identifier.required,
            "comment" => Schema.string.required.key(1),
          }

          host.result.render_mikrotik(default, cfg, "ip", "firewall", "mangle")
        end

        def self.render_firewall_mangle_src_address(host, iface, ip)
          checkIpv6Adresses(iface, ip)

          cfg = {
            "in-interface" => iface.name,
            "src-address" => ip,
            "new-routing-mark" => ip.options["routing_table"],
            "chain" => "prerouting",
            "action" => "mark-routing"
          }
          cfg['comment'] = "tag interface #{cfg['in-interface']} and src-address #{cfg['src-address']} with routing-mark #{cfg['new-routing-mark']} CONSTRUQT"

          default = {
            "chain" => Schema.identifier.required,
            "action" => Schema.identifier.required,
            "new-routing-mark" => Schema.identifier.required,
            "in-interface" => Schema.identifier.required,
            "src-address" => Schema.network.required,
            "comment" => Schema.string.required.key(1),
          }


          host.result.render_mikrotik(default, cfg, "ip", "firewall", "mangle")
        end


        def self.build_config(host, iface)
          if iface.routing_table
            render_firewall_mangle_in_interface(host, iface)
          end

          if !(iface.address.nil? || iface.address.ips.empty?)
            iface.address.ips.each do |ip|
              if ip.options["routing_table"]
                render_firewall_mangle_src_address(host, iface, ip)
              end
              render_ip(host, iface, ip)
            end

            iface.address.routes.each do |rt|
              render_route(host, iface, rt)
            end
          end
          #ret
        end
      end
    end
  end
end
