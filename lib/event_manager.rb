require 'csv'
require 'date'
require 'erb'
require 'google/apis/civicinfo_v2'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = File.read('secret.key').strip

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_phone_number(number)
  number = number.delete('^0-9')
  return 'Bad number' unless number.length == 10 || number.length == 11
  return number if number.length == 10

  if number[0] == '1'
    number[1..10]
  else
    'Bad number'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def most_frequent_hour(time)
  time.map { |hour| Time.strptime(hour, '%m/%d/%Y %H:%M') { |y| y + 2000 } }
      .map(&:hour).tally.sort_by { |_key, val| -val }
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

# contents.each do |row|
#   id = row[0]
#   name = row[:first_name]
#   zipcode = clean_zipcode(row[:zipcode])
#   legislators = legislators_by_zipcode(zipcode)

#   # form_letter = erb_template.result(binding)

#   # save_thank_you_letter(id, form_letter)
#   # clean_phone_number(row[:homephone])

#   # p Time.strptime(row[:regdate], '%m/%d/%Y %H:%M')
# end

data = CSV.table(
  'event_attendees.csv',
  header_converters: :symbol,
  headers: true
)

hour = most_frequent_hour(data[:regdate])

puts 'This is the top 3 most frequent hours'

3.times do |idx|
  puts "At #{hour[idx][0]}H, #{hour[idx][1]} people registered"
end
