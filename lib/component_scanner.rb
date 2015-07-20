require_relative 'extension_scanner'

class ComponentScanner < ExtensionScanner

  def initialize(target_uri)
    super(target_uri, 'data/components.json')
  end

  def possible_paths(name)
    paths = Array.new
    paths.push(normalize_uri('administrator', 'components', "com_#{name}"))
    paths.push(normalize_uri('components', "com_#{name}"))
    paths
  end
end
