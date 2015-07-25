require_relative 'extension_scanner'

class ComponentScanner < ExtensionScanner

  def initialize(target_uri, opts)
    super(target_uri, 'data/components.json', opts)
  end

  def possible_paths(name)
    paths = Array.new
    paths.push(normalize_uri('administrator', 'components', "com_#{name}"))
    paths.push(normalize_uri('components', "com_#{name}"))
    paths
  end
end
