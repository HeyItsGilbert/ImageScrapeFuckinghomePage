#!/usr/bin/env ruby

require 'net/http'
require 'rubygems'
require 'uri'
require 'nokogiri'

exit 1 unless ARGV.length > 0

output_dir = './out'
Dir.mkdir output_dir unless File.exists? output_dir

ARGV.each do |domain|

	outfile = lambda do |uri|
		"#{output_dir}/#{domain}/#{File.basename uri.path}"
	end
	get_response = lambda do |uri|
		Thread.exit if File.exists? outfile.call uri
		Net::HTTP.get_response uri
	end

	puts "Scraping #{domain}"
	Dir.mkdir outfile.call(URI.parse ".") unless File.exists? outfile.call(URI.parse ".")

	page = 1
	doc = Nokogiri::HTML(Net::HTTP.get(domain, "/"))
	until doc.css("#Footer .Pagination .Numeration a.Button")[0]['href'] == "/page/800"
		#puts doc.css("#Footer .Pagination .Numeration a.Button")[0]['href']
		doc = Nokogiri::HTML(Net::HTTP.get(domain, "/page/#{page}")) unless page == 1
		#puts doc
		current_page = doc.css("#Main .Post .Text a.Title")[0].text

		print "\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b"
		print "Scraping page #{current_page} ...\n"
		$stdout.flush

		threads = []
		href = doc.css("#Main .Post .Text .PostBody p a")[-1]['href']
		if /(jpg|jpeg|png|gif)/.match(href)
			print "Download #{href}\n"
			threads << Thread.new(href) do
				begin
					uri = URI.parse href
					response = get_response.call uri
					while response.kind_of? Net::HTTPRedirection
						uri = URI.parse response.header["Location"]
						response = get_response.call uri
					end
				rescue Exception => e
					puts e.inspect
				else
					File.open(outfile.call(uri), "w"){|f| f.write response.body }
				end
			end
		end

		threads.each{|t| t.join }

		page = page + 1
	end

	puts
end