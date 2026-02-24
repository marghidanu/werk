module Docr::Utils
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

    colon_pos ? {image[0...colon_pos], image[colon_pos + 1..]} : {image, "latest"}
  end

  # Decode a Docker multiplexed stream into the given output IO.
  # Each frame: [stream_type(1), padding(3), size(4 big-endian)] followed by payload.
  def self.decode_stream(input : IO, output : IO)
    loop do
      has_next = input.peek
      break if has_next.nil? || has_next.empty?

      header = Bytes.new(8)
      input.read_fully(header)
      frame_size = IO::ByteFormat::BigEndian.decode(UInt32, header[4, 4])

      IO.copy(input, output, frame_size)
    end
  rescue IO::EOFError
    Log.debug { "Reached end of Docker stream" }
  end
end
