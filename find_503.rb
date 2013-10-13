require 'net/smtp'

require 'rubygems' 
require 'mysql2'

db_password = ""
ARGV.each do|a|
  db_password = a
  print db_password
end

client = Mysql2::Client.new(:host => 'db.buildzoom.com', :database => 'bzdb', :username => "new", :password => db_password, :flags => Mysql2::Client::MULTI_STATEMENTS)


def send_email(to,opts={})
  opts[:server]      ||= 'localhost'
  opts[:from]        ||= 'dpetersen@gmail.com'
  opts[:from_alias]  ||= 'Example Emailer'
  opts[:subject]     ||= "You need to see this"
  opts[:body]        ||= "Important stuff!"

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

log_file = `tail -n 5000000 /media/drvf/logs/nginx/buildzoom.access.log | grep '1.1" 503'` 
log_file2 = `tail -n 5000000 /media/drvf/logs/nginx/buildzoom.access.log | grep '1.0" 503'` 

found = 0
counter = 0 
if (log_file.length > 5)
	lines = log_file.lines.count
	puts lines
	log_file.each_line do |line|
		counter = counter + 1
		puts "line " + counter.to_s + line + "\n\n"
		if (counter > 10) 
			exit
		end
	end
#	puts log_file 
	#send_email "dpetersen@gmail.com", :body => log_file 
	
	found = 1
#log_file.each_line do |line|
#	puts line
end

exit
if (log_file2.length > 5)
	puts log_file2
	#send_email "dpetersen@gmail.com", :body => log_file 

	found = 1
#log_file.each_line do |line|
#	puts line
end

