class SwitchConfigParser
  PORTS_DEF_REGEXP = "(Trk\\d+|\\d+|,|-)+"
  def resolvePortDefinition(portDef)
    ports = portDef.split(",").map do |rangeDef|
      range = rangeDef.split("-")
      if (range.length==1)
        range
      elsif (range.length==2)
        (range[0]..range[1]).map {|n| n }
      else
        throw "invalid range found #{rangeDef}"
      end
    end
    ports.flatten
  end
  def parse(lines)
    throw "this method must be implemented in specific flavour"
  end
end
