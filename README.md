brew install flyctl

fly auth signup

bundle init

bundle add sinatra puma

config.ru

app.rb

test:
bundle exec rackup

flyctl launch

fly deploy

takes a while

fly open

fly secrets set OPENAI_KEY=

get "/secret" do
ENV['OPENAI_KEY']
end

bundle add nokogiri json ruby-openai rerun

rerun "bundler exec rackup"
