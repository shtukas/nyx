
class NxTimeCapsules

    # NxTimeCapsules::garbageCollection()
    def self.garbageCollection()
        Database2Data::itemsForMikuType("NxTimeCommitment")
            .each{|item|

                drops = Database2Data::itemsForMikuType("NxTimeCapsule")
                            .select{|drop| drop["field10"] == item["uuid"] }

                dropnegative = drops
                                .select{|drop| drop["field1"] < 0 }
                                .first
                next if dropnegative.nil?

                droppositive = drops
                                .select{|drop| drop["field1"] > 0 }
                                .first
                next if droppositive.nil?

                puts "NxTimeCapsules::garbageCollection()"
                puts "Processing: NxTimeCommitment: #{item["description"]}"
                puts "Found: drop negative (#{dropnegative["uuid"]}): #{dropnegative["field1"]}"
                puts "Found: drop positive (#{droppositive["uuid"]}): #{droppositive["field1"]}"

                drop = {
                    "uuid"        => SecureRandom.uuid,
                    "mikuType"    => "NxTimeCapsule",
                    "unixtime"    => Time.new.to_i,
                    "datetime"    => Time.new.utc.iso8601,
                    "field1"      => droppositive["field1"] + dropnegative["field1"],
                    "field10"     => item["uuid"]
                }
                puts JSON.pretty_generate(drop)
                TodoDatabase2::commitItem(drop)

                TodoDatabase2::destroy(dropnegative["uuid"])
                TodoDatabase2::destroy(droppositive["uuid"])
            }
    end
end