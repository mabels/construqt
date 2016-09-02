
require_relative '../lib/construqt/flavour/mikrotik/result.rb'

result = Construqt::Flavour::Mikrotik::Result.new(nil)

pattern=""
20.times do |i|
  pattern += "meno#{i} ist=stink_wie_ein_luchs "
end
pattern.length.times do |i|
  #puts "#{i} == #{pattern.length}"
  lines = result.break_into_lines(pattern[0..i])
  line = lines.map do |l|
    if l[-2..-1] == " \\"
      l[0..-3]
    else
      l
    end
  end.join("")
  if line != pattern[0..i]
    puts "Err:#{i} <#{line}>\n#{lines.inspect}"
  end
  #puts "======="
  #puts lines.join(" \\\n")
end
