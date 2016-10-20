
module Construqt
  module Flavour
    module Nixian
      module Dialect
        module Ubuntu
          module Container


            def self.write_deployers(host, forme, clazz, rights, path_action)
              return [] unless i_ma_the_mother?(host)
              host.region.hosts.get_hosts.select {|h| host.eq(h.mother) }.select do |lxc|
                if forme.call(lxc)
                  host.result.add(clazz, Util.read_str(host.region, lxc.name, "deployer.sh"),
                    rights, *path_action.call(lxc)).skip_git
                  true
                end
              end
            end

            def self.i_ma_the_mother?(host)
              host.region.hosts.get_hosts.find { |h| host.eq(h.mother) }
            end

          end
        end
      end
    end
  end
end
