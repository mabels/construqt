module Construqt
  class Users
    def initialize(region)
      @region = region
      @users = {}
    end

    def add(name, cfg)
      throw "user exists #{name}" if @users[name]
      cfg['name'] = name
      cfg['yubikey'] ||= nil
      cfg['admin_c'] ||= nil
      cfg['tech_c'] ||= nil
      @users[name] = OpenStruct.new(cfg)
      @users[name].admin_c && @users[name].admin_c.set_user(@users[name])
      @users[name].tech_c && @users[name].tech_c.set_user(@users[name])
    end

    def find(name)
      @users[name]
    end

    def find_admin_cs
      @users.values.select{|user| user.admin_c }
    end

    def find_tech_cs
      @users.values.select{|user| user.tech_c }
    end

    def all
      @users.values
    end

    def get_authorized_keys(host)
      groups = [@region.get_default_group] + host.get_groups
      #puts "#{host.name} #{groups.inspect}"
      all.select do |user|
        user.public_key && groups.include?(user.group)
      end.map { |user| user.public_key.lines.map{ |i| i.strip } }.flatten
    end

  end
end
