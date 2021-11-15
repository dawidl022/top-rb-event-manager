require 'csv'
require 'google/apis/civicinfo_v2'

DATA_FILE_NAME = 'event_attendees.csv'

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
    ).officials.map(&:name).join(", ")
  rescue
    'You can find your representatives by visiting ' \
    'www.commoncause.org/take-action/find-elected-officials'
  end
end

puts "Event Manager Initialised!\n\n"

if !File.exist?(DATA_FILE_NAME)
  exit
end

puts 'Names of attendees:'

contents = CSV.open(
  DATA_FILE_NAME,
  headers: true,
  header_converters: :symbol
)

contents.each do |row|
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  puts "#{name} #{zipcode} #{legislators}"
end
