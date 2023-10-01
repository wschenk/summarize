require 'sinatra/base'
require 'kramdown'
require_relative './runner'

class App < Sinatra::Base
  use Rack::Session::Cookie, :key => 'rack.session',
      :path => '/',
      :secret => 'sosecret'
  
  get '/' do
    auth_check do
      if params[:q]
        @runner = Runner.filesystem( ["./summarize", params[:q]], {url: params[:q]} )
      end

      if request.env['HTTP_HX_TARGET'] == 'results'
        erb :results, layout: nil
      else
        erb :index
      end
    end
  end

  get '/about' do
    erb :about
  end

  # Login Stuff

  get '/login' do
    erb :login
  end

  post '/login' do
    # Add auth logic here

    session[:password] = params[:password] == ENV['MINISTER_PASSWORD']

    if !session[:password]
      @error = "Wrong password"
      erb :login
    else
      path = session.delete :redirect_to
      redirect( path || '/' )
    end
  end

  get '/logout' do
    session.clear
    redirect '/'
  end

  private
  def auth_check
    return yield unless ENV['MINISTER_PASSWORD']
    unless session[:password]
      session[:redirect_to] = request.path_info
      redirect '/login'
    else
      return yield
    end
  end
end
