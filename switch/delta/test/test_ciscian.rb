module Construqt
  module Flavour
    module Ciscian
      class CiscianTestCase < Test::Unit::TestCase
        def result_to_string(result)
          config = []
          if result.sections
            result.sections.values.each do |section|
              config << section.serialize
            end
          end
          config.join("\n")+"\n"
        end

        #compact multiple spaces to single space and remove trailing spaces after newline
        def coll_ws(str)
          str.gsub(/ +/," ").gsub(/\n +/,"\n").strip
        end

        def assert_equal_config(expected, actual)
          assert_equal(coll_ws(expected), coll_ws(actual))
        end

        def create_delta_config(dialect, old_config, nu_config)
          host=Host.new({"dialect" => dialect})

          old_result=Result.new(host)
          old_result.parse(old_config.split("\n"))
          nu_result=Result.new(host)
          nu_result.parse(nu_config.split("\n"))

          compare_result=Result.compare(nu_result, old_result)
          result_to_string(compare_result)
        end
      end
    end
  end
end
