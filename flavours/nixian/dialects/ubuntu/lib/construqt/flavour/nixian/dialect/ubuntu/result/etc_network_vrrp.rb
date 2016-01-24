module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          class Result

            class EtcNetworkVrrp
              def initialize
                @interfaces = {}
              end

              class Vrrp
                def initialize
                  @masters = []
                  @backups = []
                end

                def add_master(master, order = 0)
                  @masters << [order, master]
                  self
                end

                def add_backup(backup, order = 0)
                  @backups << [order, backup]
                  self
                end

                def render(lines, direction)
                  (["logger '#{direction}'"]+lines).map { |line| "                  #{line}" }.join("\n")
                end

                def ordered_lines(lines)
                  result = lines.inject({}){ |r, l| r[l.first] ||=[]; r[l.first] << l.last; r }
                  result.keys.sort.map { |key| result[key] }.flatten
                end

                def render_masters
                  render(ordered_lines(@masters), 'STARTING:')
                end

                def render_backups
                  render(ordered_lines(@backups), 'STOPPING:')
                end
              end

              def get(ifname)
                @interfaces[ifname] ||= Vrrp.new
              end

              def commit(result)
                unless @interfaces.keys.empty?

                  result.add(EtcConntrackdConntrackd, result.etc_conntrackd_conntrackd.commit, Construqt::Resources::Rights.root_0644(Construqt::Resources::Component::CONNTRACKD), "etc", "conntrackd", "conntrackd.conf")
                end

                @interfaces.keys.sort.each do |ifname|
                  vrrp = @interfaces[ifname]
                  result.add(self, Construqt::Util.render(binding, "vrrp_stop_script.erb"),
                    Construqt::Resources::Rights.root_0755(Construqt::Resources::Component::VRRP), "etc", "network", "vrrp.#{ifname}.stop.sh")
                  result.add(self, Construqt::Util.render(binding, "vrrp_switch_script.erb"), 
                    Construqt::Resources::Rights.root_0755(Construqt::Resources::Component::VRRP), "etc", "network", "vrrp.#{ifname}.sh")
                end
              end
            end
          end
        end
      end
    end
  end
end
