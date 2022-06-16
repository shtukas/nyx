=begin

NxOrdinal 

{
    "uuid"
    "mikuType" : "NxOrdinal"
    "type"     : "carrier"
    "line"     : String
    "ordinal"  : Float
}

{
    "uuid"
    "mikuType"   : "NxOrdinal"
    "type"       : "pointer"
    "targetUUID" : String
    "ordinal"    : Float
}

=end

=begin
    XCacheSets::values(setuuid: String): Array[Value]
    XCacheSets::set(setuuid: String, valueuuid: String, value)
    XCacheSets::getOrNull(setuuid: String, valueuuid: String): nil | Value
    XCacheSets::destroy(setuuid: String, valueuuid: String)
=end

class NxOrdinals

    # NxOrdinals::items()
    def self.items()
        XCacheSets::values("862f6f8e-e312-4163-81b4-7983d87731a6")
    end

    # NxOrdinals::issueCarrier(line, ordinal)
    def self.issueCarrier(line, ordinal)
        item = {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "NxOrdinal",
            "type"     => "carrier",
            "line"     => line,
            "ordinal"  => ordinal
        }
        XCacheSets::set("862f6f8e-e312-4163-81b4-7983d87731a6", item["uuid"], item)
        item
    end

    # NxOrdinals::delete(uuid)
    def self.delete(uuid)
        XCacheSets::destroy("862f6f8e-e312-4163-81b4-7983d87731a6", uuid)    
    end

    # NxOrdinals::toString(item)
    def self.toString(item)
        if item["type"] == "carrier" then
            return "(ordinal: #{"%5.2f" % item["ordinal"]}) #{item["line"]}"
        end
        if item["type"] == "pointer" then
            i2 = Librarian::getObjectByUUIDOrNull(item["targetUUID"])
            if i2.nil? then
                return "(NxOrdinals::toString, item not found: #{item["targetUUID"]})"
            end
            return "(ordinal: #{"%5.2f" % item["ordinal"]}) #{LxFunction::function("toString", i2)}"
        end
    end

    # NxOrdinals::done(item)
    def self.done(item)
        if item["type"] == "carrier" then
            if LucilleCore::askQuestionAnswerAsBoolean("'#{item["line"].green}' done ? ", true) then
                NxBallsService::close(item["uuid"], true)
            end
            XCacheSets::destroy("862f6f8e-e312-4163-81b4-7983d87731a6", item["uuid"])
        end
        if item["type"] == "pointer" then
            i2 = Librarian::getObjectByUUIDOrNull(item["targetUUID"])
            if i2.nil? then
                puts "(NxOrdinals::done, item not found: #{item["targetUUID"]})"
            end
            LxAction::action("done", i2)
        end
    end
end
