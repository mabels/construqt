CONSTRUQT_PATH=ENV['CONSTRUQT_PATH']||'.'
["#{CONSTRUQT_PATH}/construqt/lib"].each{|path| $LOAD_PATH.unshift(path) }

require "test/unit"
require "construqt"

module Construqt
  module Flavour
    module Ciscian
      class CiscianTestCase < Test::Unit::TestCase
        #compact multiple spaces to single space and remove trailing spaces after newline
        def collapse_whitespaces(str)
          str.gsub(/ +/," ").gsub(/\n +/,"\n").strip
        end

        def assert_equal_config(expected, actual)
          assert_equal(collapse_whitespaces(expected), collapse_whitespaces(actual))
        end

        def create_delta_config(dialect, old_config, nu_config)
          host=Host.new({"dialect" => dialect})

          old_result=Result.new(host)
          old_result.parse(old_config.split("\n"))
          nu_result=Result.new(host)
          nu_result.parse(nu_config.split("\n"))

          compare_result=Result.compare(nu_result, old_result)
          compare_result.serialize.join("\n")
        end
      end





    end
  end

end
