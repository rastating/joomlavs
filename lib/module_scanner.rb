require_relative 'extension_scanner'

class ModuleScanner < ExtensionScanner

  def initialize(target_uri, opts)
    super(target_uri, 'data/modules.json', opts)
  end

  def possible_paths(name)
    paths = Array.new
    paths.push(normalize_uri('administrator', 'modules', name))
    paths.push(normalize_uri('modules', name))
    paths
  end
end