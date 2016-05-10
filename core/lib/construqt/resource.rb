module Construqt
  class Resources
    module Component
      UNREF = :unref
      NTP = :ntp
      USB_MODESWITCH = :usb_modeswitch
      VRRP = :vrrp
      FW4 = :fw4
      FW6 = :fw6
      IPSEC = :ipsec
      SSH = :ssh
      BGP = :bgp
      OPENVPN = :openvpn
      DNS = :dns
      RADVD = :radvd
      CONNTRACKD = :conntrackd
      LXC = :lxc
      DHCPRELAY = :dhcprelay
      DNSMASQ = :dnsmasq
      WIRELESS = :wireless
    end
    module Rights
      def self.root_0600(component = Component::UNREF)
        OpenStruct.new :right => "0600", :owner => 'root', :component => component
      end
      def self.root_0644(component = Component::UNREF)
        OpenStruct.new :right => "0644", :owner => 'root', :component => component
      end
      def self.root_0755(component = Component::UNREF)
        OpenStruct.new :right => "0755", :owner => 'root', :component => component
      end
    end

    class Resource
      attr_accessor :path
      attr_accessor :right
      attr_accessor :data
    end

    class SkipFile
      attr_accessor :path
    end

    def initialize(region)
      @region = region
      @files = {}
    end

    def add_from_file(src_fname, right, key, *path)
      add_file(IO.read(src_fname), right, key, *path)
    end

    def add_skip_file(fname)
      sf = SkipFile.new
      sf.path = fname
      sf
    end

    def add_file(data, right, key, *path)
      throw "need a key" unless key
      throw "need a path #{key}" if path.empty?
      throw "resource exists with key #{key}" if @files[key]
      resource = Resource.new
      resource.path = *path
      resource.right = right
      resource.data = data
      @files[key] = resource
      resource
    end

    def find(key)
      ret = @files[key]
      throw "resource with key #{key} not found" unless ret
      ret
    end
  end
end
