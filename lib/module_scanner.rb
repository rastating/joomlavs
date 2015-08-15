require_relative 'extension_scanner'

# This class provides functionality to scan for
# vulnerable Joomla modules.
class ModuleScanner < ExtensionScanner
  def initialize(target_uri, opts)
    super(target_uri, 'data/modules.json', opts)
  end

  def possible_paths(name)
    paths = []
    paths.push(normalize_uri('administrator', 'modules', "mod_#{name}"))
    paths.push(normalize_uri('modules', "mod_#{name}"))
    paths
  end
end
