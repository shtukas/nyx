
class Forges

    # Forges::forgePermanode(description)
    def self.forgePermanode(description)
        if description.nil? then
            raise "(error: 19807ec4) description is nil"
        end
        object = {}
        object["uuid"] = SecureRandom.uuid
        object["mikuType"] = "Permanode"
        object["random"] = SecureRandom.hex(8)
        object["datetime"] = Time.new.utc.iso8601
        object["description"] = description
        object
    end

    # Forges::forgeNavigationNode(description)
    def self.forgeNavigationNode(description)
        if description.nil? then
            raise "(error: 19807ec4) description is nil"
        end
        object = {}
        object["uuid"] = SecureRandom.uuid
        object["mikuType"] = "NavigationNode"
        object["random"] = SecureRandom.hex(8)
        object["datetime"] = Time.new.utc.iso8601
        object["description"] = description
        object
    end

    # Forges::forgeNxDataText(description, text)
    def self.forgeNxDataText(description, text)
        if description.nil? then
            raise "(error: 19807ec4) description is nil"
        end
        if text.nil? then
            raise "(error: 19807ec4) text is nil"
        end
        object = {}
        object["uuid"] = SecureRandom.uuid
        object["mikuType"] = "NxDataText"
        object["random"] = SecureRandom.hex(8)
        object["datetime"] = Time.new.utc.iso8601
        object["description"] = description
        object["text"] = text
        object
    end

    # Forges::forgeNxDataUrl(description, url)
    def self.forgeNxDataUrl(description, url)
        if description.nil? then
            raise "(error: 19807ec4) description is nil"
        end
        if url.nil? then
            raise "(error: 19807ec4) url is nil"
        end
        object = {}
        object["uuid"] = SecureRandom.uuid
        object["mikuType"] = "NxDataUrl"
        object["random"] = SecureRandom.hex(8)
        object["datetime"] = Time.new.utc.iso8601
        object["description"] = description
        object["url"] = url
        object
    end

    # Forges::forgeNxDataAionPoint(description, nhash)
    def self.forgeNxDataAionPoint(description, nhash)
        if description.nil? then
            raise "(error: 19807ec4) description is nil"
        end
        if nhash.nil? then
            raise "(error: 19807ec4) nhash is nil"
        end
        object = {}
        object["uuid"] = SecureRandom.uuid
        object["mikuType"] = "NxDataAionPoint"
        object["random"] = SecureRandom.hex(8)
        object["datetime"] = Time.new.utc.iso8601
        object["description"] = description
        object["nhash"] = nhash
        object
    end

    # Forges::forgeNxDataUniqueString(description, uniquestring)
    def self.forgeNxDataUniqueString(description, uniquestring)
        if description.nil? then
            raise "(error: 19807ec4) description is nil"
        end
        if uniquestring.nil? then
            raise "(error: 19807ec4) uniquestring is nil"
        end
        object = {}
        object["uuid"] = SecureRandom.uuid
        object["mikuType"] = "NxDataUniqueString"
        object["random"] = SecureRandom.hex(8)
        object["datetime"] = Time.new.utc.iso8601
        object["description"] = description
        object["uniquestring"] = uniquestring
        object
    end

    # Forges::forgeNxDataBeacon(description, id)
    def self.forgeNxDataBeacon(description, id)
        if description.nil? then
            raise "(error: 19807ec4) description is nil"
        end
        if id.nil? then
            raise "(error: 19807ec4) id is nil"
        end
        object = {}
        object["uuid"] = SecureRandom.uuid
        object["mikuType"] = "NxDataBeacon"
        object["random"] = SecureRandom.hex(8)
        object["datetime"] = Time.new.utc.iso8601
        object["description"] = description
        object["id"] = id
        object
    end

    # Forges::forgeNxLink(uuid1, uuid2)
    def self.forgeNxLink(uuid1, uuid2)
        if uuid1.nil? then
            raise "(error: 19807ec4) uuid1 is nil"
        end
        if uuid2.nil? then
            raise "(error: dde356eb) uuid2 is nil"
        end
        if uuid1 == uuid2 then
            raise "(error: 630a0a2a) uuid1 and uuid2 cannot be equal"
        end
        if NxObjectIO::getObjectByUUIDOrNull(uuid1).nil? then
            raise "(error: 97f0d156) you are linking to non existent object #{uuid1}"
        end
        if NxObjectIO::getObjectByUUIDOrNull(uuid2).nil? then
            raise "(error: 9613ee26) you are linking to non existent object #{uuid2}"
        end
        object = {}
        object["uuid"] = SecureRandom.uuid
        object["mikuType"] = "NxLink"
        object["random"] = SecureRandom.hex(8)
        object["uuid1"] = uuid1
        object["uuid2"] = uuid2
        object
    end

    # Forges::forgeNxNote(targetuuid, text)
    def self.forgeNxNote(targetuuid, text)
        if targetuuid.nil? then
            raise "(error: 19807ec4) targetuuid is nil"
        end
        if text.nil? then
            raise "(error: 19807ec4) text is nil"
        end
        object = {}
        object["uuid"] = SecureRandom.uuid
        object["mikuType"] = "NxNote"
        object["random"] = SecureRandom.hex(8)
        object["datetime"] = Time.new.utc.iso8601
        object["targetuuid"] = targetuuid
        object["text"] = text
        object
    end
end
