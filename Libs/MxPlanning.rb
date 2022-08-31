=begin
    XCacheSets::values(setuuid: String): Array[Value]
    XCacheSets::set(setuuid: String, valueuuid: String, value)
    XCacheSets::getOrNull(setuuid: String, valueuuid: String): nil | Value
    XCacheSets::destroy(setuuid: String, valueuuid: String)
=end

class MxPlanning

    # MxPlanning::commit(item)
    def self.commit(item)
        XCacheSets::set("3df64f03-acac-460e-a39a-ed90227e6b13", item["uuid"], item)
    end

    # MxPlanning::items()
    def self.items()
        XCacheSets::values("3df64f03-acac-460e-a39a-ed90227e6b13")
    end
end
