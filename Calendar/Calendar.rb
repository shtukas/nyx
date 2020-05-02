
def pathToCalendarItems()
    "/Users/pascal/Galaxy/DataBank/Catalyst/Calendar/Items"
end

def itemsFilepaths()
    Dir.entries(pathToCalendarItems())
        .select{|filename| filename[-4, 4] == ".txt" }
        .sort
        .map{|filename| "#{pathToCalendarItems()}/#{filename}" }
end

def filePathToCatalystObject(filepath, indx)
    content = IO.read(filepath).strip
    date = File.basename(filepath)
    uuid = filepath
    {
        "uuid"            => uuid,
        "contentItem"     => {
            "type" => "line-and-body",
            "line" => date,
            "body" => date + "\n" + content
        },
        "metric"          => KeyValueStore::flagIsTrue(nil, "63bbe86e-15ae-4c0f-93b9-fb1b66278b00:#{Time.new.to_s[0, 10]}:#{uuid}") ? 0 : 0.93 - indx.to_f/10000,
        "commands"        => [],
        "defaultCommand"  => "reviewed",
        "shell-redirects" => {
            "reviewed" => "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Calendar/catalyst-objects-processing reviewed '#{uuid}'",
        }
    }
end

def catalystObjects()
    itemsFilepaths()
        .map
        .with_index{|filepath, indx| filePathToCatalystObject(filepath, indx) }
end


