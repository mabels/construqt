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
      @users[name] = OpenStruct.new(cfg)
    end

    def all
      @users.values
    end
  end
end
