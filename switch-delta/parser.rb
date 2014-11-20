class SwitchConfigParser
  PORTS_DEF_REGEXP = "([^\\d\\s]*\\d+|,|-)+"
  PORT_NAME_REGEXP="^(.*?)(\\d+)$"
  def resolvePortDefinition(portDef)
    ports = portDef.split(",").map do |rangeDef|
      range = rangeDef.split("-")
      if (range.length==1)
        range
      elsif (range.length==2)
        range[0]=~/#{PORT_NAME_REGEXP}/
        prefixFrom=$1
        from = $2
        range[1]=~/#{PORT_NAME_REGEXP}/
        prefixTo=$1
        to = $2
        throw "port prefixes differ" unless prefixFrom==prefixTo
        (from.to_i .. to.to_i).map {|n| prefixFrom + n.to_s }
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
