#!/usr/bin/ruby
if (ARGV[0]) 
	require ARGV[0]
else
	require './config.rb'
end
require 'rubygems'
require 'mechanize'
agent = Mechanize.new ; agent.user_agent = $user_agent
page_login = agent.get($base_uri + agent.get(agent.get($base_uri).body.scan(/top\.window\.document\.location\.href\s+=\s+'([^']+)'/)[0]).frames.first.src)

customernumberfield = '' ; summary_keys = Array.new ; summaries = Array.new
labelcodes = { '1st' => 0, '2nd' => 1, '3rd' => 2, '4th' => 3, '5th' => 4, '6th' => 5, '7th' => 6, '8th' => 7, '9th' => 8, '10th' => 9, '11th' => 10, '12th' => 11, '13th' => 12, '14th' => 13, '15th' => 14, '16th' => 15 }

page_login.forms.first.fields.each { |field| customernumberfield = field.name if /DBID/.match(field.name) }
page_login.forms.first[customernumberfield] = $dob + $uid
page_part2 = page_login.forms.first.submit

page_part2.forms.first.fields.each do |field|
	if (/LI6PPE/.match(field.name))
		labelcontent = page_part2.search("//label[@for='"+field.name.gsub(/\$/,'_')+"']")
		labelcontent.each do |content|
			labelcodes.keys.each do |labelcodeskey|
				if (/Enter the #{labelcodeskey} number/.match("#{labelcontent}"))
					page_part2.forms.first[field.name] = $pin[labelcodes[labelcodeskey],1]
				elsif (/Enter the #{labelcodeskey} character/.match("#{labelcontent}"))
					page_part2.forms.first[field.name] = $pass[labelcodes[labelcodeskey],1]
				end
			end
		end
	end
end

page_part3 = page_part2.forms.first.submit
page_part4 = page_part3.forms.first.submit
puts page_part4.body

page_part4.search("//table[@class='AccountTable']/thead/tr/th/a/text()").each { |heading| summary_keys.push("#{heading}") }
accounts = page_part4.search("//table[@class='AccountTable']/tbody/tr[starts-with(@title,'Select row for')]")

accounts.each do |account|
	fieldcount = 0 ; value = '' ; summary = Hash.new
	account.search("td").each do |field|
		if fieldcount == 0
			value = "#{field.search('text()')}".strip
		else
			value = "#{field.search('text()')}".strip.gsub(/[^A-Za-z0-9\-.,]/,"")
		end
		summary[summary_keys[fieldcount]] = value	
		fieldcount += 1
	end
	summaries.push(summary)
end

summaries.each do |sum|
	# if (sum["Account name"])
		puts sum["Account name"]
		sum.each do |k,v|
			puts "\t#{k}: #{v}" if k != "Account name"
		end
		puts "\tDate: " + Time.new.strftime("%Y-%m-%d %H:%M:%S")
	# end
end
