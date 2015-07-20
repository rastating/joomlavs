require_relative 'extension_scanner'

class ComponentScanner < ExtensionScanner

  def initialize(target_uri)
    super(target_uri, 'data/components.json')
    @extensions_uri = normalize_uri('administrator', 'components')
  end

  def extension_uri(name)
    normalize_uri(extensions_uri, "com_#{name}")
  end
end
