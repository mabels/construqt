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
          default = {
            "dst-address" => Schema.network.required.key(0),
            "gateway" => Schema.address,
            "type" => Schema.identifier,
            "distance" => Schema.int,
            "comment" => Schema.string.required.key(1)
          }
          cfg['comment'] = "#{cfg['dst-address']} via #{cfg['gateway']} CONSTRUQT"
          if rt.dst.ipv6?
            host.result.render_mikrotik(default, cfg, "ipv6", "route")
          else
            host.result.render_mikrotik(default, cfg, "ip", "route")
          end
        end

        def self.build_config(host, iface)
          #name = File.join(host.name, "interface", "device")
          #ret = []
          #ret += self.clazz.build_config(host, iface||self)
          if !(iface.address.nil? || iface.address.ips.empty?)
            iface.address.ips.each do |ip|
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
