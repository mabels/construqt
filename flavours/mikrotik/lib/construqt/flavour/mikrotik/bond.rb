module Construqt
  module Flavour
    class Mikrotik
      class Bond < OpenStruct
        include Construqt::Cables::Plugin::Single
        def initialize(cfg)
          super(cfg)
        end

        def scheduler_hack(host, iface)
          #binding.pry if iface.name=="sw12"
          return [] unless iface.interfaces.find{|iface| iface.class.is_a? self.class }

          system_script_schema = {
            "name" => Schema.identifier.key.required,
            "source" => Schema.source.required
          }
          host.result.render_mikrotik(system_script_schema, {
                                        "no_auto_disable" => true,
                                        "name" => "disable-#{iface.name}",
                                        "source" => <<SRC
/interface bonding disable [ find name=#{iface.name} ]
/system scheduler enable [ find name=enable-#{iface.name} ]
SRC
                                      }, "system", "script")

          or_condition = "(" + iface.interfaces.map{|iface| "name=#{iface.name}"}.join(" or ") + ")"
          host.result.render_mikrotik(system_script_schema, {
                                        "no_auto_disable" => true,
                                        "name" => "enable-#{iface.name}",
                                        "source" => <<SRC
:local run [ /interface bonding find running=yes and #{or_condition}]
:if ($run!="") do={
/interface bonding enable [find name=sw12]
/system schedule disable [ find name=enable-sw12 ]
}
SRC
                                      }, "system", "script")

          system_scheduler_script = {
            "name" => Schema.identifier.key.required,
            "on-event" => Schema.identifier.required,
            "start-time" => Schema.identifier.null,
            "interval" => Schema.interval.null,
            "disabled" => Schema.boolean.default(false)
          }
          host.result.render_mikrotik(system_scheduler_script, {
                                        "name" => "disable-#{iface.name}",
                                        "on-event" => "disable-#{iface.name}",
                                        "start-time" => "startup"
                                      }, "system", "scheduler")

          host.result.render_mikrotik(system_scheduler_script, {
                                        "name" => "enable-#{iface.name}",
                                        "on-event" => "enable-#{iface.name}",
                                        "interval" => "00:00:10",
                                        "disabled" => true
                                      }, "system", "scheduler")
        end

        def build_config(host, iface)
          iface = iface.delegate
          default = {
            "mode" => Schema.string.default("active-backup"),
            "mtu" => Schema.int.required,
            "name" => Schema.identifier.required.key,
            "slaves" => Schema.identifiers.required,
          }
          host.result.render_mikrotik(default, {
                                        "mtu" => iface.mtu,
                                        "name" => iface.name,
                                        "mode" => iface.mode,
                                        "slaves" => iface.interfaces.map{|iface| iface.name}.join(',')
                                      }, "interface", "bonding")
          Interface.build_config(host, iface)
          scheduler_hack(host, iface)
        end
      end
    end
  end
end
