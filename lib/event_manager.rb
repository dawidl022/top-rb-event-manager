puts "Event Manager Initialised!\n\n"

puts 'Names of attendees:'

if File.exist?('event_attendees.csv')
  lines = File.readlines('event_attendees.csv')
  lines[1..].each do |line|
    puts line.split(",")[2]
  end
end
