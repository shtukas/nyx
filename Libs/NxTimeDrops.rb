
class NxTimeDrops

    # NxTimeDrops::start(item)
    def self.start(item)
        raise "(error: e1a10f12-5c9e-46e2-9527-3b4f6eff3dc6)" if item["mikuType"] != "NxTimeDrop"
        return if item["field2"] # We are already running
        TodoDatabase2::set(item["uuid"], "field2", Time.new.to_i)
    end

    # NxTimeDrops::stop(item)
    def self.stop(item)
        raise "(error: b515455a-d9b9-4241-8839-ffe3a42025bd)" if item["mikuType"] != "NxTimeDrop"
        return if item["field2"].nil? # We are not running
        unrealisedTimeInHours = (Time.new.to_i - item["field2"]).to_f/3600
        item["field1"] = item["field1"] - unrealisedTimeInHours # field1 then possibly became negative
        item["field2"] = nil
        TodoDatabase2::commitItem(item)
    end

    # NxTimeDrops::garbageCollection()
    def self.garbageCollection()
        Database2Data::itemsForMikuType("NxTimeCommitment")
            .each{|item|

                drops = Database2Data::itemsForMikuType("NxTimeDrop")

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

                puts "NxTimeDrops::garbageCollection()"
                puts "Processing: NxTimeCommitment: #{item["description"]}"
                puts "Found: drop negative (#{dropnegative["uuid"]}): #{dropnegative["field1"]}"
                puts "Found: drop positive (#{droppositive["uuid"]}): #{droppositive["field1"]}"
                sum = droppositive["field1"] + dropnegative["field1"]
                TodoDatabase2::set(droppositive["uuid"], "field1", sum)
                TodoDatabase2::destroy(dropnegative["uuid"])
            }
    end
end