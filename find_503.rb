require 'net/smtp'
require 'rubygems' 
require 'mysql2'

puts "hi"

db_password = ""

ARGV.each do|a|
  db_password = a
end

client = Mysql2::Client.new(:host => 'db.buildzoom.com', :database => 'bzdb', :username => "new", :password => db_password, :flags => Mysql2::Client::MULTI_STATEMENTS)

def send_email(to,opts={})
  opts[:server]      ||= 'localhost'
  opts[:from]        ||= 'david@buildzoom.com'
  opts[:subject]     ||= "Nginx errors found"
  opts[:body]        ||= "503 errors found in nginx log!"

  msg = <<END_OF_MESSAGE
From: #{opts[:from_alias]} <#{opts[:from]}>
To: <#{to}>
Subject: #{opts[:subject]}

#{opts[:body]}
END_OF_MESSAGE

  Net::SMTP.start(opts[:server]) do |smtp|
    smtp.send_message msg, opts[:from], to
  end
end

log_file = `tail -n 5000 /media/drvf/logs/nginx/buildzoom.access.log | grep '1.1" 503'` 
#log_file2 = `tail -n 10000 /media/drvf/logs/nginx/buildzoom.access.log | grep '1.0" 503'` 

if (log_file.length > 1)
	log_file.each_line do |line|
		if (line =~ /\[(.*?)\] "GET (.*?) HTTP.*?503 \d+ "-" "(.*?)"/)
puts line
			error_date = client.escape($1)
			url = client.escape($2)
			user_agent = client.escape($3)
			query_string = "insert ignore into 503_errors (error_date, error_ua, error_url) values ('#{error_date}','#{user_agent}','#{url}')"
			client.query(query_string)
		end
	end
end

query = "select id, error_date, error_ua, error_ip, error_url from 503_errors where emailed = 0"
counter = 0

my_string = ""

results = client.query(query)
results.each do |row|
	counter = counter + 1
	query2 = "update 503_errors set emailed = 1 where id = #{row['id']}"
	client.query(query2)
	my_string = my_string + "error_date: " + row['error_date'] + " error_url: " + row['error_ua'] + "error_url: " + row['error_url'] + "\n"
end

if counter > 1
	puts "sending email\n"
	send_email "dpetersen@gmail.com", :body => my_string 
	send_email "gerard@buildzoom.com", :body => my_string 
	send_email "alitvak@buildzoom.com", :body => my_string 
end

