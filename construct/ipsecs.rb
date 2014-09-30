
module Construct
module Ipsecs
  class Ipsec < OpenStruct
    def initialize(cfg)
      super(cfg)
    end
    def build_config()
      self.left.build_config()  
      self.right.build_config()  
    end
  end
  @ipsecs = {}
  def self.add_connection(cfg, id, to_id, iname)
    throw "my not found #{cfg[id].inspect}" unless cfg[id]['my']
    throw "host not found #{cfg[id].inspect}" unless cfg[id]['host']
    throw "remote not found #{cfg[id].inspect}" unless cfg[id]['remote']
    cfg[id]['other'] = nil
    cfg[id]['cfg'] = nil
    cfg[id]['my'].host = cfg[id]['host']  
    cfg[id]['my'].name = "#{iname}-#{cfg[id]['host'].name}"
    cfg[id]['interface'] = nil
    cfg[id] = cfg[id]['host'].flavour.create_ipsec(cfg[id])
  end
  def self.connection(name, cfg)
    add_connection(cfg, 'left', 'right', Util.add_gre_prefix(cfg['right']['host'].name))
    add_connection(cfg, 'right', 'left', Util.add_gre_prefix(cfg['left']['host'].name))
    cfg['name'] = name
    cfg = @ipsecs[name] = Ipsec.new(cfg)
    cfg.left.other = cfg.right
    cfg.left.cfg = cfg
    cfg.right.other = cfg.left
    cfg.right.cfg = cfg

    #puts "-------- #{cfg.left.my.host.name} - #{cfg.right.my.host.name}"
    cfg.left.interface = Interfaces.add_gre(cfg.left.my.host, Util.clean_if("gre6", cfg.left.other.host.name),
                                            "address" => cfg.left.my,
                                            "local" => cfg.left.remote.first_ipv6,
                                            "remote" => cfg.right.remote.first_ipv6
                                          )
    cfg.right.interface = Interfaces.add_gre(cfg.right.my.host, Util.clean_if("gre6", cfg.right.other.host.name), 
                                            "address" => cfg.right.my,
                                            "local" => cfg.right.remote.first_ipv6,
                                            "remote" => cfg.left.remote.first_ipv6
                                          )
    #binding.pry
    cfg
  end
  def self.build_config()
    @ipsecs.each do |name, ipsec|
      ipsec.build_config()
    end
  end
  
end
end
