require 'subprocess'

module SbtPlugin
  class SbtProcess
    def initialize(project_dir)
      @project_dir = project_dir
    end

    def send_command(command, wait_for = /\A>\z/)
      process.stdin.puts(command)
      drain_stdout(wait_for)
    end

    def process
      @process ||= Dir.chdir(@project_dir) do
        Subprocess::Process.new(['sbt'], stdin: Subprocess::PIPE, stdout: Subprocess::PIPE)
      end
    end

    private

    def drain_stdout(wait_for)
      drain_stdout!(wait_for)
    rescue EOFError, Errno::EPIPE
      process.stdout.close
    end

    def drain_stdout!(wait_for)
      buffer ||= []
      loop do
        process.stdout.read_nonblock(4096).each_line do |line|
          buffer << line
          return buffer.join if line.strip =~ wait_for
        end
      end
    rescue Errno::EWOULDBLOCK, Errno::EAGAIN
      retry
    end
  end
end
