require 'sinatra/base'
require 'open3'
require 'digest'

class App < Sinatra::Base
  get '/' do
    erb :index
  end

  get '/about' do
    erb :about
  end

  get '/block' do
    erb :block
  end

  post '/block' do
      if params[:text].nil? || params[:text] == ""
        return "Please enter some text"
      end

      stdout_str, stderr_str, status = Open3.capture3("./summarize_text", stdin_data: params[:text])

      if status.success?
        return stdout_str
      else
        return "Command failed with status #{status.exitstatus}:\n#{stderr_str}"
      end
  end

  get '/summarize' do
    @url = params[:url]

    if @url.nil? || @url == ""
      @error = 'Please pass in a url'
    else
      @runner = Runner.new( ["./summarize", @url ], url: @url )
    end

    if request.env['HTTP_HX_TARGET'] == 'results'
      erb :results, layout: nil
    else
      erb :index
    end
  end

  post '/test' do
    command = ['./summarize', params[:url]]

    stdout_str, stderr_str, status = Open3.capture3(*command)

    if status.success?
      return stdout_str
    else
      return "Command failed with status #{status.exitstatus}:\n#{stderr_str}"
    end
  end
end

class Runner
  def initialize( cmd, keys )
    @state = {
      cmd: cmd,
      keys: keys,
      started_at: nil,
      finished_at: nil,
      key: Digest::MD5.hexdigest( cmd.join ),
      running: false
    }

    load_state

    run_if_not_started
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

  def state_dir
    "/tmp/runner"
  end

  def load_state
    FileUtils.mkdir_p state_dir
    file = "#{state_dir}/#{key}"
    if File.exist? file
      puts "Loading #{file}"
      begin
        @state = JSON.parse( File.read( file ),{symbolize_names: true} )

        @state[:started_at] = Time.new( @state[:started_at] ) if @state[:started_at]
        @state[:finished_at] = Time.new( @state[:finished_at] ) if @state[:finished_at]
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

  def duration
    if finished?
      return finished_at - started_at
    else
      return Time.now - started_at
    end
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

end