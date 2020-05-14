
def pathToCalendarItems()
    "/Users/pascal/Galaxy/DataBank/Catalyst/Calendar/Items"
end

def today()
    Time.new.to_s[0, 10]
end

def dates()
    Dir.entries(pathToCalendarItems())
    .select{|filename| filename[-4, 4] == ".txt" }
    .sort
    .map{|filename| filename[0, 10] }
end

def dateToFilepath(date)
    "#{pathToCalendarItems()}/#{date}.txt"
end

def filePathToCatalystObject(date, indx)
    filepath = dateToFilepath(date)
    content = IO.read(filepath).strip
    uuid = "8413-9d175a593282-#{date}"
    {
        "uuid"            => uuid,
        "contentItem"     => {
            "type" => "line-and-body",
            "line" => date,
            "body" => content
        },
        "metric"          => KeyValueStore::flagIsTrue(nil, "63bbe86e-15ae-4c0f-93b9-fb1b66278b00:#{Time.new.to_s[0, 10]}:#{date}") ? 0 : 0.93 - indx.to_f/10000,
        "commands"        => ["open"],
        "defaultCommand"  => "reviewed", 
        "shell-redirects" => {
            "reviewed" => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Calendar/catalyst-objects-processing reviewed '#{date}'",
            "open" => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Calendar/catalyst-objects-processing open '#{date}'",
        }
    }
end

def catalystObjects()
    dates()
        .map
        .with_index{|date, indx| filePathToCatalystObject(date, indx) }
end


