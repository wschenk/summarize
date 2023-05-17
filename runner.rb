require 'open3'
require 'digest'
require 'json'
require 'time'
require 'redis'

class Runner
  def self.inline( cmd, keys = {})
    InlineRunner.new( cmd, keys )
  end

  def self.filesystem( cmd, keys = {})
    FilesystemRunner.new( cmd, keys )
  end

  def self.redis( cmd, keys = {})
    RedisRunner.new( cmd, keys )
  end

  def initialize( cmd, keys )
    @state = {
      cmd: cmd,
      keys: keys,
      key: Digest::MD5.hexdigest( cmd.join ),
      running: false
    }

    load_state

    run_if_not_started
  end

  def started_at; @state[:started_at]; end
  def finished_at; @state[:finished_at]; end
  def started?; @state[:started_at]; end
  def running?; @state[:running]; end
  def finished?; @state[:finished_at]; end
  def key; @state[:key]; end
  def success?; @state[:success]; end
  def stdout; @state[:stdout]; end
  def stderr; @state[:stderr]; end
  def duration
    if finished?
      return finished_at - started_at
    else
      return Time.now - started_at
    end
  end
end

class InlineRunner < Runner
  def initialize( cmd, keys )
    super( cmd, keys )
  end

  def load_state
    # noop
  end

  def run_if_not_started
    @state[:started_at] =  Time.now
    stdout_str, stderr_str, status = Open3.capture3(*@state[:cmd])
    @state[:finished_at] = Time.now

    @state[:success] = status.success?
    @state[:stdout] = stdout_str
    @state[:stderr] = stderr_str
  end
end

class FilesystemRunner < Runner
  def initialize( cmd, args )
    super( cmd, args )
  end

  def state_dir
    "/tmp/runner"
  end

  def load_state
    FileUtils.mkdir_p state_dir
    file = "#{state_dir}/#{key}"
    if File.exist? file
      puts "Loading #{file}"
      begin
        @state = JSON.parse( File.read( file ), {symbolize_names: true} )

        @state[:started_at] = Time.parse( @state[:started_at] ) if @state[:started_at]
        @state[:finished_at] = Time.parse( @state[:finished_at] ) if @state[:finished_at]
      rescue JSON::ParserError
        puts "Couldn't parse #{file}"
      end
    end
  end

  def save_state
    puts "Saving state to #{state_dir}/#{key}"
    FileUtils.mkdir_p state_dir
    File.open( "#{state_dir}/#{key}", "w" ) do |out|
      out << JSON.pretty_generate( @state )
    end
  end

  def run_if_not_started
    if !started?
      @state[:started_at] = Time.now
      @state[:pid] = fork do
        puts "In the fork!"
        stdout_str, stderr_str, status = Open3.capture3(*@state[:cmd])
        load_state
        @state[:finished_at] = Time.now

        @state[:success] = status.success?
        @state[:stdout] = stdout_str
        @state[:stderr] = stderr_str

        save_state
      end

      save_state
    end
  end
end

class RedisRunner < FilesystemRunner
  def initialize( cmd, args )
    super( cmd, args )

    @key = @state[:key]
    @redis = Redis.new
  end

  def redis
    redis = Redis.new
    r = yield( redis )
    redis.close
    r
  end

  def load_state
    redis do |r|
      state = r.get @state[:key]
      if state
        @state = JSON.parse( state, {symbolize_names: true} )
        @state[:started_at] = Time.parse( @state[:started_at] ) if @state[:started_at]
        @state[:finished_at] = Time.parse( @state[:finished_at] ) if @state[:finished_at]
      end
      puts "State is now #{@state}"
    end
  end

  def save_state
    redis do |r|
      puts "Setting state #{@state}"
      r.set @state[:key], JSON.generate( @state )
      r.sadd "jobs", @state[:key]
    end
  end

  def self.jobs
    r = Redis.new
    ret = r.smembers
    r.close
    ret
  end
end
