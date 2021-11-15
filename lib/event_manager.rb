require 'csv'

DATA_FILE_NAME = 'event_attendees.csv'

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
  zipcode = row[:zipcode]
  puts "#{name} #{zipcode}"
end
