require 'sinatra/base'
require 'open3'

class App < Sinatra::Base
  get '/' do    
    File.read( "public/index.html" )
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