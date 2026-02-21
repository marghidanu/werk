module Werk::Executors
  class Docker < Base
    Log = ::Log.for(self)

    def initialize
      @client = Docr::Client.new
      @running_container_ids = Array(String).new
    end

    protected def perform(
      ctx : Werk::Context,
      job : Werk::Config::Job,
      output : IO,
    ) : Int32
      docker_job = job.as(Werk::Config::DockerJob)

      # Ensure the image is available locally
      if @client.images.exists?(docker_job.image)
        Log.debug { "Image #{docker_job.image} was found locally" }
      else
        Log.debug { "Fetching image #{docker_job.image}" }
        repository, tag = Docr::Utils.parse_repository_tag(docker_job.image)
        @client.images.pull(repository, tag)
      end

      # Create container
      container_name = "#{Digest::MD5.hexdigest(ctx.name)}-#{ctx.session_id}"
      Log.debug { "Creating container '#{container_name}'" }
      container = @client.containers.create(
        container_name,
        Docr::ContainerConfig.new(
          image: docker_job.image,
          entrypoint: docker_job.entrypoint,
          cmd: ["-c", job.script_content],
          working_dir: "/opt/workspace",
          env: ctx.variables,
          host_config: Docr::HostConfig.new(
            network_mode: docker_job.network_mode,
            binds: [
              "#{Path[ctx.directory].expand}:/opt/workspace",
            ].concat(docker_job.volumes)
          ),
          labels: {
            "com.stuffo.werk.name"       => ctx.name,
            "com.stuffo.werk.session_id" => ctx.session_id.to_s,
          }
        )
      )

      @running_container_ids << container.id

      begin
        Log.debug { "Starting container '#{container_name}'" }
        @client.containers.start(container.id)

        Log.debug { "Streaming logs for '#{container_name}'" }
        @client.containers.logs(container.id, output: output, follow: true, stdout: true, stderr: true)

        # Wait for the container execution to end and retrieve the exit code.
        status = @client.containers.wait(container.id)
      ensure
        Log.debug { "Removing container '#{container_name}'" }
        @client.containers.delete(container.id, force: true)
        @running_container_ids.delete(container.id)
      end

      status.status_code
    end

    def terminate : Nil
      return if @running_container_ids.empty?

      @running_container_ids.each do |container_id|
        Log.debug { "Terminating container '#{container_id}'" }
        @client.containers.kill(container_id, "SIGTERM")
      rescue ex
        Log.debug { "Failed to kill container #{container_id}: #{ex.message}" }
      end

      @running_container_ids.clear
    end
  end
end
