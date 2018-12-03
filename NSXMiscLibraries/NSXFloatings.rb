
# encoding: UTF-8

FLOATINGS_DATA_FILEPATH = "/Galaxy/DataBank/Catalyst/Floatings/data.json"

=begin
Floating {
    "uuid"     : String, UUID
    "unixtime" : Integer
    "line"     : String
}
=end

class NSXFloatings
    
    # NSXFloatings::getFloatings()
    def self.getFloatings() # Array[Floating]
        JSON.parse(IO.read(FLOATINGS_DATA_FILEPATH))
    end

    # NSXFloatings::putDataToDisk(floatings)
    def self.putDataToDisk(floatings)
        File.open(FLOATINGS_DATA_FILEPATH, "w"){|f| f.puts(JSON.pretty_generate(floatings)) }
    end

    # NSXFloatings::removeItemFromData(floatings, floating)
    def self.removeItemFromData(floatings, floating)
        floatings.reject{|f| f["uuid"]==floating["uuid"] }
    end

    # NSXFloatings::issueFloating(line)
    def self.issueFloating(line)
        floating = {}
        floating["uuid"] = SecureRandom.hex
        floating["unixtime"] = Time.new.to_i
        floating["line"] = line
        NSXFloatings::putDataToDisk( NSXFloatings::getFloatings() + [floating] )
        floating
    end

    # NSXFloatings::interactivelySelectAndRemoveOneFloating()
    def self.interactivelySelectAndRemoveOneFloating()
        floating = LucilleCore::selectEntityFromListOfEntitiesOrNull("floatings: ", NSXFloatings::getFloatings(), lambda{|floating| floating["line"] })
        floatings = NSXFloatings::removeItemFromData(NSXFloatings::getFloatings(), floating)
        NSXFloatings::putDataToDisk(floatings)
    end

end
