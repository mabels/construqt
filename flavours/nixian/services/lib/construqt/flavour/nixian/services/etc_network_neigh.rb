module Construqt
  module Flavour
    module Nixian
      module Services

            class Neigh
              def initialize(name)
                @name = name
                @ups = []
                @downs = []
              end
              def commit(result)
                !@ups.empty? && result.add(Neigh, (['#!/bin/sh']+@ups).join("\n"),
                  Construqt::Resources::Rights.root_0755,
                  'etc', 'network', "#{@name}-neigh-up.sh")
                !@downs.empty? && result.add(Neigh, (['#!/bin/sh']+@downs.reverse).join("\n"),
                  Construqt::Resources::Rights.root_0755,
                  'etc', 'network', "#{@name}-neigh-down.sh")
              end

              def up(line)
                @ups.push line
              end
              def down(line)
                @downs.push line
              end

            end

            class EtcNetworkNeigh
              attr_reader :ifaces
              def initialize
                @ifaces = {}
              end

              def get(name, &block)
                iface = @ifaces[name]
                unless iface
                  @ifaces[name] = iface = Neigh.new(name)
                  block && block.call(iface)
                end
                iface
              end

              def commit(result)
                ifaces.values.each do |iface|
                  iface.commit(result)
                end
              end
            end
          end
        end
      end
    end
