#!/usr/bin/env ruby

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'httparty'
end

if ARGV[0].nil?
  puts "Pass in a url"
  exit 1
end

response = HTTParty.post( "https://twilight-butterfly-9726.fly.dev/summarize", body: {url: ARGV[0]})
puts response.body
