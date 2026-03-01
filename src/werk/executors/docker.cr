module Werk::Executors
  class Docker < Base
    Log = ::Log.for(self)

    # Per-image pull locks: when parallel jobs share an image, only the
    # first one pulls while the others wait, avoiding redundant downloads.
    @@pull_mutexes = Hash(String, Mutex).new
    @@pull_meta_mutex = Mutex.new

    @container_id : String?
    @client : Docr::Client?

    private def client : Docr::Client
      @client ||= Docr::Client.new
    end

    protected def perform(
      ctx : Werk::Context,
      job_config : Werk::Config::Job,
      output : IO,
    ) : Int32
      job = job_config.as(Werk::Config::DockerJob)
      image = interpolation.interpolate(job.image)
      entrypoint = interpolation.interpolate_all(job.entrypoint)
      volumes = interpolation.interpolate_all(job.volumes)
      network_mode = interpolation.interpolate(job.network_mode)

      # Ensure the image is available locally (one pull per image)
      ensure_image(image, output)

      # Create container
      container_name = "#{Digest::MD5.hexdigest(ctx.name)}-#{ctx.session_id}"
      Log.debug { "Creating container '#{container_name}'" }
      container = client.containers.create(
        container_name,
        Docr::Types::ContainerConfig.new(
          image: image,
          entrypoint: entrypoint,
          cmd: ["-c", job.commands.join("\n")],
          working_dir: "/opt/workspace",
          env: interpolation.variables,
          host_config: Docr::Types::HostConfig.new(
            network_mode: network_mode,
            binds: [
              "#{Path[ctx.directory].expand}:/opt/workspace",
            ].concat(volumes)
          ),
          labels: {
            "com.stuffo.werk.name"       => ctx.name,
            "com.stuffo.werk.session_id" => ctx.session_id.to_s,
          }
        )
      )

      @container_id = container.id

      begin
        Log.debug { "Starting container '#{container_name}'" }
        client.containers.start(container.id)

        Log.debug { "Streaming logs for '#{container_name}'" }
        client.containers.logs(container.id, output: output, follow: true, stdout: true, stderr: true)

        # Wait for the container execution to end and retrieve the exit code.
        status = client.containers.wait(container.id)
      ensure
        Log.debug { "Removing container '#{container_name}'" }
        client.containers.delete(container.id, force: true)
        @container_id = nil
      end

      status.status_code
    end

    def terminate : Nil
      if container_id = @container_id
        Log.debug { "Terminating container '#{container_id}'" }
        client.containers.kill(container_id, "SIGTERM")
      end
    rescue ex : Docr::Error
      Log.debug { "Failed to kill container: #{ex.message}" }
    end

    private def ensure_image(image : String, output : IO) : Nil
      mutex = @@pull_meta_mutex.synchronize do
        @@pull_mutexes[image] ||= Mutex.new
      end

      mutex.synchronize do
        if client.images.exists?(image)
          Log.debug { "Image #{image} was found locally" }
        else
          output.puts "Pulling image #{image}..."
          repository, tag = Docr::Utils.parse_repository_tag(image)
          client.images.pull(repository, tag)
          output.puts "Image #{image} pulled successfully"
        end
      end
    end
  end
end
