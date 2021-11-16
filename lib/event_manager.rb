require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

DATA_FILE_NAME = 'event_attendees.csv'
TEMPLATE_FILE_NAME = 'form_letter.erb'
OUTPUT_DIR = 'output'

def clean_zipcode(zipcode)
  zipcode.to_s[0, 5].rjust(5, "0")
end

def clean_phone_number(number)
  number = number.to_s.split("").select { |char| char =~ /[0-9]/}.join("")

  if number.length < 10 || number.length > 11
    nil
  elsif number.length == 11
    if number[0] == "1"
      number[1, 10]
    else
      nil
    end
  else
    number
  end
end

def note_registration_time(recorded_hours, registration_date)
  registration_hour = Time.parse(registration_date.split()[1]).hour
  recorded_hours[registration_hour] += 1
end

def note_registration_weekday(recorded_weekdays, registration_date)
  registration_weekday = Time.strptime(registration_date.split()[0], "%m/%e/%y")
    .wday
  recorded_weekdays[registration_weekday] += 1
end

def analyse_hours(hours)
  (0..23).map do |hour|
    "#{hour}: #{(hours[hour] || 0)}"
  end
end

def analyse_weekdays(weekdays)
  (0..6).map do |weekday_index|
    "#{Date::DAYNAMES[weekday_index]}: #{weekdays[weekday_index]}"
  end
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting ' \
    'www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  file_name = "output/thanks_#{id}.html"

  File.open(file_name, 'w') do |file|
    file.puts form_letter
  end
end

def gen_letters(id, name, zipcode)
  @template_letter ||= File.read(TEMPLATE_FILE_NAME)
  @erb_template ||= ERB.new(@template_letter)

  legislators = legislators_by_zipcode(zipcode)

  form_letter = @erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

puts "Event Manager Initialised!"

if !File.exist?(DATA_FILE_NAME)
  exit
end


contents = CSV.open(
  DATA_FILE_NAME,
  headers: true,
  header_converters: :symbol
)

Dir.mkdir(OUTPUT_DIR) unless Dir.exist?(OUTPUT_DIR)

time_frequencies = Hash.new(0)
weekday_frequencies = Hash.new(0)
make_letters = ARGV.include?("letters")

puts "\nNames and phone numbers of attendants:"
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  number = clean_phone_number(row[:homephone])
  registration_date = row[:regdate]

  note_registration_time(time_frequencies, registration_date)
  note_registration_weekday(weekday_frequencies, registration_date)

  if make_letters
    gen_letters(id, name, zipcode)
  end

  puts "#{name} #{number}"
end

puts "\nAnalysis of registration hours:"
puts analyse_hours(time_frequencies)

puts "\nAnalysis of registration days of the week:"
puts analyse_weekdays(weekday_frequencies)
