
class NxTimeCapsules

    # NxTimeCapsules::stop(item)
    def self.stop(item)
        raise "(error: b515455a-d9b9-4241-8839-ffe3a42025bd)" if item["mikuType"] != "NxTimeCapsule"
        return if item["field2"].nil? # We are not running
        unrealisedTimeInHours = (Time.new.to_i - item["field2"]).to_f/3600
        item["field1"] = item["field1"] - unrealisedTimeInHours # field1 then possibly became negative
        item["field2"] = nil
        TodoDatabase2::commitItem(item)
    end

    # NxTimeCapsules::garbageCollection()
    def self.garbageCollection()
        Database2Data::itemsForMikuType("NxTimeCommitment")
            .each{|item|

                drops = Database2Data::itemsForMikuType("NxTimeCapsule")

                dropnegative = drops
                                .select{|drop| drop["field4"] == item["uuid"] }
                                .select{|drop| drop["field2"].nil? }
                                .select{|drop| drop["field1"] < 0 }
                                .first
                next if dropnegative.nil?

                droppositive = drops
                                .select{|drop| drop["field4"] == item["uuid"] }
                                .select{|drop| drop["field2"].nil? }
                                .select{|drop| drop["field1"] > 0 }
                                .first
                next if droppositive.nil?

                puts "NxTimeCapsules::garbageCollection()"
                puts "Processing: NxTimeCommitment: #{item["description"]}"
                puts "Found: drop negative (#{dropnegative["uuid"]}): #{dropnegative["field1"]}"
                puts "Found: drop positive (#{droppositive["uuid"]}): #{droppositive["field1"]}"
                sum = droppositive["field1"] + dropnegative["field1"]
                TodoDatabase2::set(droppositive["uuid"], "field1", sum)
                TodoDatabase2::destroy(dropnegative["uuid"])
            }
    end
end