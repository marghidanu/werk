require "./docr/client"
require "./docr/types"
require "./docr/images"
require "./docr/containers"

module Docr
  # Parse a Docker image reference into repository and tag.
  # Examples:
  #   "alpine"         => {"alpine", "latest"}
  #   "alpine:3.18"    => {"alpine", "3.18"}
  #   "my/repo:v1.0"   => {"my/repo", "v1.0"}
  def self.parse_repository_tag(image : String) : {String, String}
    # Handle images with a port in the registry (e.g., "registry:5000/image:tag")
    # The tag separator is the last colon after the last slash
    last_slash = image.rindex('/')
    colon_search_start = last_slash ? last_slash + 1 : 0
    colon_pos = image.index(':', colon_search_start)

    if colon_pos
      {image[0...colon_pos], image[colon_pos + 1..]}
    else
      {image, "latest"}
    end
  end
end
