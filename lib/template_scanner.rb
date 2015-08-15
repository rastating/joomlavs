require_relative 'extension_scanner'

# This class provides functionality to scan for
# vulnerable Joomla templates.
class TemplateScanner < ExtensionScanner
  def initialize(target_uri, opts)
    super(target_uri, 'data/templates.json', opts)
  end

  def possible_paths(name)
    paths = []
    paths.push(normalize_uri('administrator', 'templates', name))
    paths.push(normalize_uri('templates', name))
    paths
  end

  def queue_requests(name, path_index = 0, &block)
    paths = possible_paths(name)
    return unless path_index < paths.length

    uri = normalize_uri(paths[path_index], 'templateDetails.xml')
    req = create_request(uri)
    req.on_complete do |resp|
      if resp.code == 200
        block.call(resp, paths[path_index], uri)
      else
        queue_requests(name, path_index + 1, &block)
      end
    end

    hydra.queue req
  end
end
