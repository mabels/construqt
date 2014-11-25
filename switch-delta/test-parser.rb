CONSTRUCT_PATH=ENV['CONSTRUCT_PATH']||'..'
["#{CONSTRUCT_PATH}/ipaddress/lib","#{CONSTRUCT_PATH}/construct"].each{|path| $LOAD_PATH.unshift(path) }

require("construct/construct.rb")





module Construct
  module Flavour
    module Ciscian

      def self.putsResult(result)
        puts("--- RESULT ---")
        result.sections.sections.values.each do |section|
          puts section.serialize
        end
      end


      host=Host.new({"dialect" => "dlink-dgs15xx"})

      oldConfig = []
      while ( line = $stdin.gets )
        oldConfig << line.chomp
      end
      oldResult=Result.new(host)
      oldResult.parse(oldConfig)

      newConfig = []
      while ( line = ARGF.gets )
        newConfig << line
      end
      newResult=Result.new(host)
      newResult.parse(newConfig)

      compareResult=newResult.compare(oldResult)
      putsResult(compareResult)

    end
  end
end
