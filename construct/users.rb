module Construct
module Users
	@users = {}
	def self.add(name, cfg)
		cfg['name'] = name
		cfg['yubikey'] ||= nil
		@users[name] ||= OpenStruct.new(cfg)
	end 
	def self.users
		@users.values
	end
end

end
