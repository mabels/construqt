module Construqt
  module Flavour
    module Nixian
      module Services
        module SysCtlConf
          class Service
            include Construqt::Util::Chainable
            chainable_attr_value :fname
            attr_reader :values
            def initialize
              @values = {}
              self.fname("/etc/sysctl.conf")
            end
            def set(key, value)
              @values[key] = value
              self
            end
          end

          class OncePerHost
            def activate(ctx)
              @context = ctx
              @values = {}
            end

            def build_config_interface(iface)
              if iface.address.routes.routes.find{ |rt| rt.kind_of?(Construqt::Addresses::RaRoute) }
                  @values["net.ipv6.conf.#{iface.name}.accept_ra"] = 2
              end
            end

            def commit # (host, service)
              result = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::Result::OncePerHost)
              #host.result.add(self, skeys.join(), Construqt::Resources::Rights.root_0644, "etc", "shadow.merge")
              values = {}
              values["net.ipv4.conf.all.forwarding"] = 1
              values["net.ipv4.vs.pmtu_disc"] = 1
              values["net.ipv6.conf.all.autoconf"] = 0
              values["net.ipv6.conf.all.accept_ra"] = 0
              values["net.ipv6.conf.all.forwarding"] = 1
              values["net.ipv6.conf.all.proxy_ndp"] = 1
              @values.each { |k,v| values[k] = v }
              # read all service_types and merge
              fname = nil
              @context.find_by_service_type(Service).service_producers.each do |si|
                # binding.pry
                throw "mutiple fname not allowed" if fname && si.srv_inst.get_fname != fname
                fname = si.srv_inst.get_fname
                si.srv_inst.values.each do |k, v|
                  values[k] = v
                end
              end
              result.add(self, values.map{|k,v| k.to_s+" = "+v.to_s}.join("\n"),
                         Construqt::Resources::Rights.root_0600, *File.split(fname))


              up_downer = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::UpDowner::OncePerHost)
              up_downer.add(@host, Taste::SysCtlConf.new)

              # etc_systemd_service = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcSystemdService::OncePerHost)
              # sysctl_service = Construqt::Flavour::Nixian::Services::EtcSystemdService::SystemdService
              #    .new("systemd-sysctl.service")
              #    .skip_content
              #    .command("restart")
              # etc_systemd_service.add_units(sysctl_service)
            end
          end

          class Action
          end

          module Taste
            class SysCtlConf
              class Systemd
                def on_add(ud, taste, _, me)
                  ess = @context.find_instances_from_type(Construqt::Flavour::Nixian::Services::EtcSystemdService::OncePerHost)
                  ess.get("systemd-sysctl.service") do |srv|
                    srv.skip_content.command("restart")
                  end
                end
                def activate(ctx)
                  @context = ctx
                  self
                end
              end
            end
          end


          class Factory
            attr_reader :machine
            def start(service_factory)
              @machine ||= service_factory.machine
                .service_type(Service)
                .result_type(OncePerHost)
                .depend(Result::Service)
                .activator(Construqt::Flavour::Nixian::Services::UpDowner::Activator.new
                  .entity(Taste::SysCtlConf)
                  .add(Construqt::Flavour::Nixian::Tastes::Systemd::Factory, Taste::SysCtlConf::Systemd))
            end

            def produce(host, srv_inst, ret)
              Action.new
            end
          end
        end
      end
    end
  end
end
