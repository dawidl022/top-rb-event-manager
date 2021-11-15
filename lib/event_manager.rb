require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

DATA_FILE_NAME = 'event_attendees.csv'
TEMPLATE_FILE_NAME = 'form_letter.erb'
OUTPUT_DIR = 'output'

def clean_zipcode(zipcode)
  zipcode.to_s[0, 5].rjust(5, "0")
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

puts "Event Manager Initialised!"

if !File.exist?(DATA_FILE_NAME)
  exit
end


contents = CSV.open(
  DATA_FILE_NAME,
  headers: true,
  header_converters: :symbol
)

template_letter = File.read(TEMPLATE_FILE_NAME)
erb_template = ERB.new(template_letter)

Dir.mkdir(OUTPUT_DIR) unless Dir.exist?(OUTPUT_DIR)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end
