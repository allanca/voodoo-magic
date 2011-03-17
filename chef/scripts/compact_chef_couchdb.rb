# vim:ts=2:expandtab
require 'rubygems'
require 'open-uri'
require 'json'

#http://wiki.apache.org/couchdb/Compaction

if JSON::parse(open("http://localhost:5984/chef").read)["disk_size"] > 100_000_000
  res = Net::HTTP.post_form(URI.parse('http://localhost:5984/chef/_compact'), {})
  puts res.body
end

%w(nodes roles registrations clients data_bags data_bag_items users).each do |view|
  puts "check for clean: #{view}"
  begin
    res = open("http://localhost:5984/chef/_design/#{view}/_info")
    if JSON::parse(res.read)['view_index']["disk_size"] > 100_000_000
      res = Net::HTTP.post_form(URI.parse("http://localhost:5984/chef/_compact/#{view}"), {})
      puts res.body
    end
  rescue
  end
end

