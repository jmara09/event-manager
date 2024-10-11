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
  return 'Incorrect phone number format.' unless number.length == 10 || number.length == 11

  if number.length == 10
    number[0..10]
  else
    number[0] == '1' ? number[1..10] : 'Incorrect phone number format.'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def convert_strings(array)
  array.map { |hour| Time.strptime(hour, '%m/%d/%Y %H:%M') { |y| y + 2000 } }
end

def frequent_hours(time)
  convert_strings(time).map(&:hour).tally.sort_by { |_key, val| -val }
end

def frequest_days(days)
  convert_strings(days).map { |date| date.to_date.wday }
                       .map { |day| Date::DAYNAMES[day] }.tally
                       .sort_by { |_key, val| -val }
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  homephone = clean_phone_number(row[:homephone])

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

data = CSV.table(
  'event_attendees.csv',
  header_converters: :symbol,
  headers: true
)

hour = frequent_hours(data[:regdate])
day = frequest_days(data[:regdate])

hour.each do |row|
  puts "At #{row[0]}H, #{row[1]} people registered"
end

day.each do |row|
  puts "On #{row[0]}, #{row[1]} people registered"
end
