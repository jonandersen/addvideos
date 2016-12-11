devices = [
  "iPhone 7",
  "iPhone 7 Plus",
  "iPhone 5",
  "iPhone 4s",
  "iPad Retina",
  "iPad Pro"
]


all_devices = `xcrun simctl list devices`

`xcodebuild -project ./Scripts/Scripts.xcodeproj -scheme Scripts clean` #make sure to clean before starting

all_devices.split("\n").each do |line|
  parsed = line.match(/\s+([\w\s]+)\s\(([\w\-]+)\)/) || []
  next unless parsed.length == 3 # we don't care about those headers
  _, name, id = parsed.to_a
  if devices.include?(name)
    puts "Adding media to device #{name} (#{id})"
  
    destination = "-destination 'platform=iOS Simulator,id=#{id},OS=10.1'"
    puts "`xcodebuild -project ./Scripts/Scripts.xcodeproj -scheme Scripts #{destination} clean build test`"
    `xcodebuild -project ./Scripts/Scripts.xcodeproj -scheme Scripts #{destination} build test`
  end
end