require "../spec_helper"

describe Werk::Executors::Local do
  it "Crystal's internal process fiber corrupts exit code on broken pipe" do
    Signal::PIPE.ignore

    reader, writer = IO.pipe
    reader.close

    # Old approach: let Crystal's internal fiber handle the copy.
    # The fiber hits EPIPE, closes the internal pipe early, and the
    # child process gets killed by SIGPIPE → wrong exit code.
    process = Process.new("echo", args: ["hello"],
      output: writer,
      error: Process::Redirect::Close,
    )

    status = process.wait
    writer.close rescue nil

    # echo should return 0, but Crystal's broken fiber kills it
    status.exit_code.should_not eq(0)
  end

  it "should handle broken output pipe gracefully with manual copy" do
    Signal::PIPE.ignore

    reader, writer = IO.pipe
    reader.close

    # New approach: use Redirect::Pipe and copy ourselves with rescue.
    # The child process runs to completion unaffected.
    process = Process.new("echo", args: ["hello"],
      output: Process::Redirect::Pipe,
      error: Process::Redirect::Pipe,
    )

    done = Channel(Nil).new(2)

    spawn do
      IO.copy(process.output, writer) rescue nil
      done.send(nil)
    end

    spawn do
      IO.copy(process.error, writer) rescue nil
      done.send(nil)
    end

    status = process.wait
    2.times { done.receive }
    writer.close rescue nil

    status.exit_code.should eq(0)
  end
end
