
=begin

{
    "mikuTypeToObjectuuids": Map[MikuType, Array[Objectuuid]]
    "itemXs": Map[Itemuuid, ItemX]
}

ItemX = {
    "item"        => Item
    "description" => String
}

=end

$AlphaStructure = nil

class AlphaStructure

    # --------------------------------------------------------
    # Ops

    # AlphaStructure::loadFromSaveOrError()
    def self.loadFromSaveOrError()
        data = XCache::getOrNull("#{Stargate::cachePrefix()}:5529f769-4f39-4bed-bf0e-248e3ba4b43d")
        raise "(error: 99182d97-fa3f-43e7-8f38-37302ba2a428)" if data.nil?
        $AlphaStructure = JSON.parse(data)
    end

    # AlphaStructure::upgrade(row, commitToDiskAfterUpgrade)
    def self.upgrade(row, commitToDiskAfterUpgrade)
        raise "(error: 99182d97-fa3f-43e7-8f38-37302ba2a428)" if $AlphaStructure.nil?

        readValue = lambda{|value|
            begin 
                JSON.parse(row["_eventData3_"])
            rescue
                row["_eventData3_"]
            end
        }

        objectuuid = row["_objectuuid_"]
        attname    = row["_eventData2_"]
        attvalue   = readValue.call(row["_eventData3_"])

        $AlphaStructure["ItemX"] = $AlphaStructure["ItemX"] || {}
        $AlphaStructure["ItemX"][objectuuid] = $AlphaStructure["ItemX"][objectuuid] || {"item" => {}, "description" => nil}
        $AlphaStructure["ItemX"][objectuuid]["item"][attname] = attvalue

        protoitem = $AlphaStructure["ItemX"][objectuuid]["item"].clone
        description = LxFunction::function("generic-description-for-AlphaStructure-or-Null", protoitem)
        if description then
            $AlphaStructure["ItemX"][objectuuid]["description"] = description
        end

        if row["_eventData2_"] == "mikuType" then
            objectuuid = row["_objectuuid_"]
            mikuType   = JSON.parse(row["_eventData3_"])
            $AlphaStructure["mikuTypeToObjectuuids"][mikuType] = $AlphaStructure["mikuTypeToObjectuuids"][mikuType] || []
            $AlphaStructure["mikuTypeToObjectuuids"][mikuType] = ($AlphaStructure["mikuTypeToObjectuuids"][mikuType] + [objectuuid]).uniq
        end
        if commitToDiskAfterUpgrade then
            XCache::set("#{Stargate::cachePrefix()}:5529f769-4f39-4bed-bf0e-248e3ba4b43d", JSON.generate($AlphaStructure))
        end
    end

    # AlphaStructure::sendAlphaStructureToDisk()
    def self.sendAlphaStructureToDisk()
        XCache::set("#{Stargate::cachePrefix()}:5529f769-4f39-4bed-bf0e-248e3ba4b43d", JSON.generate($AlphaStructure))
    end

    # AlphaStructure::buildFromScratch()
    def self.buildFromScratch()
        object = {
            "mikuTypeToObjectuuids" => {},
            "itemXs" => {},
        }
        $AlphaStructure = object

        db = SQLite3::Database.new(Fx18s::fx18Filepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("select * from _fx18_ order by _eventTime_", []) do |row|
            puts "AlphaStructure::buildFromScratch() @ eventuuid: #{row["_eventuuid_"]}"
            AlphaStructure::upgrade(row, false)
        end
        db.close
        AlphaStructure::sendAlphaStructureToDisk()
    end

    # AlphaStructure::ensure()
    def self.ensure()
        begin
            AlphaStructure::loadFromSaveOrError()
        rescue
            AlphaStructure::buildFromScratch()
        end
    end

    # --------------------------------------------------------
    # Data

    # AlphaStructure::mikuTypeToObjectuuids(mikuType)
    def self.mikuTypeToObjectuuids(mikuType)
        $AlphaStructure["mikuTypeToObjectuuids"][mikuType] = $AlphaStructure["mikuTypeToObjectuuids"][mikuType] || []
        $AlphaStructure["mikuTypeToObjectuuids"][mikuType].clone
    end

    # AlphaStructure::nx20s()
    def self.nx20s()
        $AlphaStructure["itemXs"]
            .values
            .map {|itemX|
                item = itemX["item"]
                description = itemX["description"]
                {
                    "announce"   => "(#{item["mikuType"]}) #{description}",
                    "unixtime"   => item["unixtime"],
                    "objectuuid" => item["uuid"]
                }
            }
    end

    # AlphaStructure::mikuTypeCount(mikuType)
    def self.mikuTypeCount(mikuType)
        $AlphaStructure["mikuTypeToObjectuuids"][mikuType] = $AlphaStructure["mikuTypeToObjectuuids"][mikuType] || []
        $AlphaStructure["mikuTypeToObjectuuids"][mikuType].size
    end

    # AlphaStructure::aliveItemOrNull(objectuuid)
    def self.aliveItemOrNull(objectuuid)
        return nil if $AlphaStructure["ItemX"][objectuuid].nil?
        item = $AlphaStructure["ItemX"][objectuuid]["item"]
        return nil if (!item["isAlive"].nil? and !item["isAlive"])
        item.clone
    end

    # AlphaStructure::mikuTypeToItems(mikuType)
    def self.mikuTypeToItems(mikuType)
        AlphaStructure::mikuTypeToObjectuuids(mikuType)
            .map{|objectuuid| AlphaStructure::aliveItemOrNull(objectuuid) }
            .compact
    end

    # AlphaStructure::mikuTypeToItems2(mikuType, count)
    def self.mikuTypeToItems2(mikuType, count)
        AlphaStructure::mikuTypeToObjectuuids(mikuType)
            .first(count)
            .map{|objectuuid| AlphaStructure::aliveItemOrNull(objectuuid) }
            .compact
    end

    # --------------------------------------------------------

    # AlphaStructure::removeObjectuuid(objectuuid)
    def self.removeObjectuuid(objectuuid)
        $AlphaStructure["ItemX"].delete(objectuuid)
    end

    # AlphaStructure::processEvent(event)
    def self.processEvent(event)
        if event["mikuType"] == "(object has been logically deleted)" then
            objectuuid = event["objectuuid"]
            $AlphaStructure["ItemX"].delete(objectuuid)
        end

        if event["mikuType"] == "NxDeleted" then
            objectuuid = event["objectuuid"]
            $AlphaStructure["ItemX"].delete(objectuuid)
        end
    end
end
