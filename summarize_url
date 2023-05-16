#!/usr/bin/env ruby

require 'net/http'
require 'nokogiri'
require 'json'

if ARGV[0].nil?
  $stderr.puts "summarize_url <url>"
  exit 1
end

url = ARGV[0]
unless url =~  URI::DEFAULT_PARSER.regexp[:ABS_URI]
  $stderr.puts "#{url} is not a valid URL"
  exit 1
end

uri = URI(ARGV[0])
response = Net::HTTP.get_response(uri)

doc = Nokogiri::HTML(response.body)

doc.xpath('//script').remove # remove script tags
doc.xpath('//style').remove  # remove style tags
text = doc.xpath('//text()').text.strip.gsub(/\s\s/, "")

puts text
