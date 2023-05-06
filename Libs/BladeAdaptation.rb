
=begin
Blades
    Blades::init(mikuType, uuid)
    Blades::uuidToFilepathOrNull(uuid)
    Blades::setAttribute2(uuid, attribute_name, value)
    Blades::getAttributeOrNull1(filepath, attribute_name)
    Blades::getMandatoryAttribute1(filepath, attribute_name)
    Blades::addToSet1(filepath, set_id, element_id, value)
    Blades::removeFromSet1(filpath, set_id, element_id)
    Blades::putDatablob1(filepath, key, datablob)
    Blades::getDatablobOrNull1(filepath, key)
=end

=begin
MikuTypes
    MikuTypes::mikuTypeUUIDsCached(mikuType) # Cached
    MikuTypes::mikuTypeUUIDsEnumeratorFromDiskScan(mikuType)
=end

class BladeAdaptation

    # BladeAdaptation::mikuTypes()
    def self.mikuTypes()
        [
            "NxAnniversary",
            "NxBackup",
            "NxBoard",
            "NxOndate",
            "NxTask",
            "NxTimePromise",
            "NxLong",
            "NxLine",
            "NxFloat",
            "NxFire",
            "NxMonitor1",
            "PhysicalTarget",
            "Wave",
        ]
    end

    # BladeAdaptation::readFileAsItemOrError(filepath)
    def self.readFileAsItemOrError(filepath)
        raise "(error: 5d519cf9-680a-4dab-adda-6fa160ef9f47)" if !File.exist?(filepath)
        mikuType = Blades::getMandatoryAttribute1(filepath, "mikuType")
        if mikuType == "NxAnniversary" then
            item = {}
            item["uuid"] = Blades::getMandatoryAttribute1(filepath, "uuid")
            item["mikuType"] = mikuType
            item["unixtime"] = Blades::getMandatoryAttribute1(filepath, "unixtime")
            item["datetime"] = Blades::getMandatoryAttribute1(filepath, "datetime")
            item["description"] = Blades::getMandatoryAttribute1(filepath, "description")
            item["startdate"] = Blades::getMandatoryAttribute1(filepath, "startdate")
            item["repeatType"] = Blades::getMandatoryAttribute1(filepath, "repeatType")
            item["lastCelebrationDate"] = Blades::getAttributeOrNull1(filepath, "lastCelebrationDate")
        end

        if mikuType == "NxBoard" then
            item = {}
            item["uuid"] = Blades::getMandatoryAttribute1(filepath, "uuid")
            item["mikuType"] = mikuType
            item["unixtime"] = Blades::getMandatoryAttribute1(filepath, "unixtime")
            item["datetime"] = Blades::getMandatoryAttribute1(filepath, "datetime")
            item["description"] = Blades::getMandatoryAttribute1(filepath, "description")
            item["engine"] = Blades::getMandatoryAttribute1(filepath, "engine")
        end

        if mikuType == "NxTask" then
            item = {}
            item["uuid"] = Blades::getMandatoryAttribute1(filepath, "uuid")
            item["mikuType"] = mikuType
            item["unixtime"] = Blades::getMandatoryAttribute1(filepath, "unixtime")
            item["datetime"] = Blades::getMandatoryAttribute1(filepath, "datetime")
            item["description"] = Blades::getMandatoryAttribute1(filepath, "description")
            item["position"] = Blades::getMandatoryAttribute1(filepath, "position")
            item["engine"] = Blades::getMandatoryAttribute1(filepath, "engine")
        end

        if mikuType == "NxOndate" then
            item = {}
            item["uuid"] = Blades::getMandatoryAttribute1(filepath, "uuid")
            item["mikuType"] = mikuType
            item["unixtime"] = Blades::getMandatoryAttribute1(filepath, "unixtime")
            item["datetime"] = Blades::getMandatoryAttribute1(filepath, "datetime")
            item["description"] = Blades::getMandatoryAttribute1(filepath, "description")
        end

        if mikuType == "Wave" then
            item = {}
            item["uuid"] = Blades::getMandatoryAttribute1(filepath, "uuid")
            item["mikuType"] = mikuType
            item["unixtime"] = Blades::getMandatoryAttribute1(filepath, "unixtime")
            item["datetime"] = Blades::getMandatoryAttribute1(filepath, "datetime")
            item["description"] = Blades::getMandatoryAttribute1(filepath, "description")
            item["nx46"] = Blades::getMandatoryAttribute1(filepath, "nx46")
            item["lastDoneDateTime"] = Blades::getMandatoryAttribute1(filepath, "lastDoneDateTime")

            item["interruption"] = Blades::getAttributeOrNull1(filepath, "interruption")
            item["onlyOnDays"] = Blades::getAttributeOrNull1(filepath, "onlyOnDays")
        end

        if mikuType == "PhysicalTarget" then
            item = {}
            item["uuid"] = Blades::getMandatoryAttribute1(filepath, "uuid")
            item["mikuType"] = mikuType
            item["description"] = Blades::getMandatoryAttribute1(filepath, "description")
            item["dailyTarget"] = Blades::getMandatoryAttribute1(filepath, "dailyTarget")
            item["date"] = Blades::getMandatoryAttribute1(filepath, "date")
            item["counter"] = Blades::getMandatoryAttribute1(filepath, "counter")
            item["lastUpdatedUnixtime"] = Blades::getMandatoryAttribute1(filepath, "lastUpdatedUnixtime")
        end

        if mikuType == "NxTimePromise" then
            item = {}
            item["uuid"] = Blades::getMandatoryAttribute1(filepath, "uuid")
            item["mikuType"] = mikuType
            item["unixtime"] = Blades::getMandatoryAttribute1(filepath, "unixtime")
            item["account"] = Blades::getMandatoryAttribute1(filepath, "account")
            item["value"] = Blades::getMandatoryAttribute1(filepath, "value")
        end

        if mikuType == "NxLong" then
            item = {}
            item["uuid"] = Blades::getMandatoryAttribute1(filepath, "uuid")
            item["mikuType"] = mikuType
            item["unixtime"] = Blades::getMandatoryAttribute1(filepath, "unixtime")
            item["datetime"] = Blades::getMandatoryAttribute1(filepath, "datetime")
            item["description"] = Blades::getMandatoryAttribute1(filepath, "description")
            item["active"] = Blades::getMandatoryAttribute1(filepath, "active")
        end

        if mikuType == "NxLine" then
            item = {}
            item["uuid"] = Blades::getMandatoryAttribute1(filepath, "uuid")
            item["mikuType"] = mikuType
            item["unixtime"] = Blades::getMandatoryAttribute1(filepath, "unixtime")
            item["datetime"] = Blades::getMandatoryAttribute1(filepath, "datetime")
            item["description"] = Blades::getMandatoryAttribute1(filepath, "description")
        end

        if mikuType == "NxFloat" then
            item = {}
            item["uuid"] = Blades::getMandatoryAttribute1(filepath, "uuid")
            item["mikuType"] = mikuType
            item["unixtime"] = Blades::getMandatoryAttribute1(filepath, "unixtime")
            item["datetime"] = Blades::getMandatoryAttribute1(filepath, "datetime")
            item["description"] = Blades::getMandatoryAttribute1(filepath, "description")
        end

        if mikuType == "NxFire" then
            item = {}
            item["uuid"] = Blades::getMandatoryAttribute1(filepath, "uuid")
            item["mikuType"] = mikuType
            item["unixtime"] = Blades::getMandatoryAttribute1(filepath, "unixtime")
            item["datetime"] = Blades::getMandatoryAttribute1(filepath, "datetime")
            item["description"] = Blades::getMandatoryAttribute1(filepath, "description")
        end

        if mikuType == "NxBackup" then
            item = {}
            item["uuid"] = Blades::getMandatoryAttribute1(filepath, "uuid")
            item["mikuType"] = mikuType
            item["unixtime"] = Blades::getMandatoryAttribute1(filepath, "unixtime")
            item["datetime"] = Blades::getMandatoryAttribute1(filepath, "datetime")
            item["description"] = Blades::getMandatoryAttribute1(filepath, "description")
            item["periodInDays"] = Blades::getMandatoryAttribute1(filepath, "periodInDays")
            item["lastDoneUnixtime"] = Blades::getMandatoryAttribute1(filepath, "lastDoneUnixtime")
        end

        if mikuType == "NxMonitor1" then
            item = {}
            item["uuid"] = Blades::getMandatoryAttribute1(filepath, "uuid")
            item["mikuType"] = mikuType
            item["description"] = Blades::getMandatoryAttribute1(filepath, "description")
            item["engine"] = Blades::getMandatoryAttribute1(filepath, "engine")
        end

        if item then
            item["field11"] = Blades::getAttributeOrNull1(filepath, "field11")
            item["boarduuid"] = Blades::getAttributeOrNull1(filepath, "boarduuid")
            item["doNotShowUntil"] = Blades::getAttributeOrNull1(filepath, "doNotShowUntil")
            item["note"] = Blades::getAttributeOrNull1(filepath, "note")
            item["tmpskip1"] = Blades::getAttributeOrNull1(filepath, "tmpskip1")
            return item
        end

        raise "(error: 17844ff9-8aa1-4cc7-a477-a4479a8a74ac) BladeAdaptation::readFileAsItemOrError is currently not supporting mikuType: #{mikuType}."
    end

    # BladeAdaptation::getItemOrNull(uuid)
    def self.getItemOrNull(uuid)
        filepath = Blades::uuidToFilepathOrNull(uuid)
        return nil if filepath.nil?
        item = XCache::getOrNull("c5895d3a-0667-472d-a9ff-5997a199077a:#{filepath}")
        return JSON.parse(item) if item
        item = BladeAdaptation::readFileAsItemOrError(filepath)
        item[:blade] = filepath
        XCache::set("c5895d3a-0667-472d-a9ff-5997a199077a:#{filepath}", JSON.generate(item))
        return item
    end

    # BladeAdaptation::commitItem(item)
    def self.commitItem(item)
        filepath = Blades::uuidToFilepathOrNull(item["uuid"])
        if filepath.nil? then
            raise "(error: 22a3cfc8-7325-4a3e-b9e2-7f12cf22d192) Could not determine filepath of assumed blade for item: #{item}"
        end

        uuid = item["uuid"]

        Blades::setAttribute2(uuid, "field11", item["field11"])
        Blades::setAttribute2(uuid, "boarduuid", item["boarduuid"])
        Blades::setAttribute2(uuid, "doNotShowUntil", item["doNotShowUntil"])
        Blades::setAttribute2(uuid, "note", item["note"])
        Blades::setAttribute2(uuid, "tmpskip1", item["tmpskip1"])

        if item["mikuType"] == "NxAnniversary" then
            # We do not need to (re)set the uuid
            Blades::setAttribute2(uuid, "mikuType", item["mikuType"])
            Blades::setAttribute2(uuid, "unixtime", item["unixtime"])
            Blades::setAttribute2(uuid, "datetime", item["datetime"])
            Blades::setAttribute2(uuid, "description", item["description"])
            Blades::setAttribute2(uuid, "startdate", item["startdate"])
            Blades::setAttribute2(uuid, "repeatType", item["repeatType"])
            Blades::setAttribute2(uuid, "lastCelebrationDate", item["lastCelebrationDate"])
            return
        end

        if item["mikuType"] == "NxBoard" then
            # We do not need to (re)set the uuid
            Blades::setAttribute2(uuid, "mikuType", item["mikuType"])
            Blades::setAttribute2(uuid, "unixtime", item["unixtime"])
            Blades::setAttribute2(uuid, "datetime", item["datetime"])
            Blades::setAttribute2(uuid, "description", item["description"])
            Blades::setAttribute2(uuid, "engine", item["engine"])
            return
        end

        if item["mikuType"] == "NxTask" then
            # We do not need to (re)set the uuid
            Blades::setAttribute2(uuid, "mikuType", item["mikuType"])
            Blades::setAttribute2(uuid, "unixtime", item["unixtime"])
            Blades::setAttribute2(uuid, "datetime", item["datetime"])
            Blades::setAttribute2(uuid, "description", item["description"])
            Blades::setAttribute2(uuid, "position", item["position"])
            Blades::setAttribute2(uuid, "engine", item["engine"])
            return
        end

        if item["mikuType"] == "NxOndate" then
            # We do not need to (re)set the uuid
            Blades::setAttribute2(uuid, "mikuType", item["mikuType"])
            Blades::setAttribute2(uuid, "unixtime", item["unixtime"])
            Blades::setAttribute2(uuid, "datetime", item["datetime"])
            Blades::setAttribute2(uuid, "description", item["description"])
            Blades::setAttribute2(uuid, "engine", item["engine"])
            return
        end

        if item["mikuType"] == "Wave" then
            # We do not need to (re)set the uuid
            Blades::setAttribute2(uuid, "mikuType", item["mikuType"])
            Blades::setAttribute2(uuid, "unixtime", item["unixtime"])
            Blades::setAttribute2(uuid, "datetime", item["datetime"])
            Blades::setAttribute2(uuid, "description", item["description"])
            Blades::setAttribute2(uuid, "nx46", item["nx46"])
            Blades::setAttribute2(uuid, "lastDoneDateTime", item["lastDoneDateTime"])
            Blades::setAttribute2(uuid, "onlyOnDays", item["onlyOnDays"])
            Blades::setAttribute2(uuid, "interruption", item["interruption"])
            return
        end

        if item["mikuType"] == "PhysicalTarget" then
            # We do not need to (re)set the uuid
            Blades::setAttribute2(uuid, "mikuType", item["mikuType"])
            Blades::setAttribute2(uuid, "description", item["description"])
            Blades::setAttribute2(uuid, "dailyTarget", item["dailyTarget"])
            Blades::setAttribute2(uuid, "date", item["date"])
            Blades::setAttribute2(uuid, "counter", item["counter"])
            Blades::setAttribute2(uuid, "lastUpdatedUnixtime", item["lastUpdatedUnixtime"])
            return
        end

        if item["mikuType"] == "NxTimePromise" then
            # We do not need to (re)set the uuid
            Blades::setAttribute2(uuid, "mikuType", item["mikuType"])
            Blades::setAttribute2(uuid, "unixtime", item["unixtime"])
            Blades::setAttribute2(uuid, "account", item["account"])
            Blades::setAttribute2(uuid, "value", item["value"])
            return
        end

        if item["mikuType"] == "NxLong" then
            # We do not need to (re)set the uuid
            Blades::setAttribute2(uuid, "mikuType", item["mikuType"])
            Blades::setAttribute2(uuid, "unixtime", item["unixtime"])
            Blades::setAttribute2(uuid, "datetime", item["datetime"])
            Blades::setAttribute2(uuid, "description", item["description"])
            Blades::setAttribute2(uuid, "active", item["active"])
            return
        end

        if item["mikuType"] == "NxLine" then
            # We do not need to (re)set the uuid
            Blades::setAttribute2(uuid, "mikuType", item["mikuType"])
            Blades::setAttribute2(uuid, "unixtime", item["unixtime"])
            Blades::setAttribute2(uuid, "datetime", item["datetime"])
            Blades::setAttribute2(uuid, "description", item["description"])
            return
        end

        if item["mikuType"] == "NxFloat" then
            # We do not need to (re)set the uuid
            Blades::setAttribute2(uuid, "mikuType", item["mikuType"])
            Blades::setAttribute2(uuid, "unixtime", item["unixtime"])
            Blades::setAttribute2(uuid, "datetime", item["datetime"])
            Blades::setAttribute2(uuid, "description", item["description"])
            return
        end

        if item["mikuType"] == "NxFire" then
            # We do not need to (re)set the uuid
            Blades::setAttribute2(uuid, "mikuType", item["mikuType"])
            Blades::setAttribute2(uuid, "unixtime", item["unixtime"])
            Blades::setAttribute2(uuid, "datetime", item["datetime"])
            Blades::setAttribute2(uuid, "description", item["description"])
            return
        end

        if item["mikuType"] == "NxBackup" then
            # We do not need to (re)set the uuid
            Blades::setAttribute2(uuid, "mikuType", item["mikuType"])
            Blades::setAttribute2(uuid, "unixtime", item["unixtime"])
            Blades::setAttribute2(uuid, "datetime", item["datetime"])
            Blades::setAttribute2(uuid, "description", item["description"])
            Blades::setAttribute2(uuid, "periodInDays", item["periodInDays"])
            Blades::setAttribute2(uuid, "lastDoneUnixtime", item["lastDoneUnixtime"])
            return
        end

        if item["mikuType"] == "NxMonitor1" then
            # We do not need to (re)set the uuid
            Blades::setAttribute2(uuid, "mikuType", item["mikuType"])
            Blades::setAttribute2(uuid, "description", item["description"])
            Blades::setAttribute2(uuid, "engine", item["engine"])
            return
        end

        raise "(error: b90c4fc6-0096-469c-8a04-3b224283f80d) un-supported mikuType: #{item["mikuType"]}"
    end

    # BladeAdaptation::mikuTypeItems(mikuType) # Array[Items]
    def self.mikuTypeItems(mikuType)
        MikuTypes::mikuTypeUUIDsCached(mikuType)
            .map{|uuid| BladeAdaptation::getItemOrNull(uuid) }
            .compact
    end

    # BladeAdaptation::getMikuTypeCount(mikuType)
    def self.getMikuTypeCount(mikuType)
        MikuTypes::mikuTypeUUIDsCached(mikuType).size
    end

    # BladeAdaptation::getAllCatalystItemsEnumerator()
    def self.getAllCatalystItemsEnumerator()
        Enumerator.new do |items|
            BladeAdaptation::mikuTypes().each{|mikuType|
                MikuTypes::mikuTypeToBladesFilepathsEnumerator(mikuType).each{|filepath|
                    uuid = Blades::getMandatoryAttribute1(filepath, "uuid")
                    items << BladeAdaptation::getItemOrNull(uuid)
                }
            }

        end
    end

    # BladeAdaptation::fsckItem(item)
    def self.fsckItem(item)
        CoreData::fsck(item["uuid"], item["field11"])
    end

    # BladeAdaptation::fsck()
    def self.fsck()
        # We use a .to_a here because otherwise the error is not propagated up (Ruby weirdness)
        BladeAdaptation::getAllCatalystItemsEnumerator().to_a.each{|item|
            BladeAdaptation::fsckItem(item)
        }
    end
end
