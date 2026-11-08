
class Fsck

    # Fsck::fsckObject(object)
    def self.fsckObject(object)
        if object["mikuType"] == "NxDeleted" then
            return
        end
        if object["mikuType"] == "Permanode" then
            if object["uuid"].nil? then
                raise "(error: d4fa1c3e) missing uuid in object: #{JSON.pretty_generate(object)}"
            end
            if object["datetime"].nil? then
                raise "(error: 2cf4da17) missing datetime in object: #{JSON.pretty_generate(object)}"
            end
            if object["description"].nil? then
                raise "(error: 2cf4da17) missing description in object: #{JSON.pretty_generate(object)}"
            end
            return
        end
        if object["mikuType"] == "NavigationNode" then
            if object["uuid"].nil? then
                raise "(error: d4fa1c3e) missing uuid in object: #{JSON.pretty_generate(object)}"
            end
            if object["datetime"].nil? then
                raise "(error: 2cf4da17) missing datetime in object: #{JSON.pretty_generate(object)}"
            end
            if object["description"].nil? then
                raise "(error: 2cf4da17) missing description in object: #{JSON.pretty_generate(object)}"
            end
            return
        end
        if object["mikuType"] == "NxDataText" then
            if object["uuid"].nil? then
                raise "(error: 5e9abafa) missing uuid in object: #{JSON.pretty_generate(object)}"
            end
            if object["description"].nil? then
                raise "(error: 2cf4da17) missing description in object: #{JSON.pretty_generate(object)}"
            end
            if object["text"].nil? then
                raise "(error: ca7bd8a0) missing text in object: #{JSON.pretty_generate(object)}"
            end
            return
        end

        if object["mikuType"] == "NxDataUrl" then
            if object["uuid"].nil? then
                raise "(error: 5e9abafa) missing uuid in object: #{JSON.pretty_generate(object)}"
            end
            if object["description"].nil? then
                raise "(error: 2cf4da17) missing description in object: #{JSON.pretty_generate(object)}"
            end
            if object["url"].nil? then
                raise "(error: ca7bd8a0) missing url in object: #{JSON.pretty_generate(object)}"
            end
            return
        end

        if object["mikuType"] == "NxDataAionPoint" then
            if object["uuid"].nil? then
                raise "(error: 5e9abafa) missing uuid in object: #{JSON.pretty_generate(object)}"
            end
            if object["description"].nil? then
                raise "(error: 2cf4da17) missing description in object: #{JSON.pretty_generate(object)}"
            end
            if object["nhash"].nil? then
                raise "(error: ca7bd8a0) missing nhash in object: #{JSON.pretty_generate(object)}"
            end
            nhash = object["nhash"]
            AionFsck::structureCheckAionHashRaiseErrorIfAny(Elizabeth.new(), nhash)
            return
        end

        if object["mikuType"] == "NxDataUniqueString" then
            if object["uuid"].nil? then
                raise "(error: 5e9abafa) missing uuid in object: #{JSON.pretty_generate(object)}"
            end
            if object["description"].nil? then
                raise "(error: 2cf4da17) missing description in object: #{JSON.pretty_generate(object)}"
            end
            if object["uniquestring"].nil? then
                raise "(error: ca7bd8a0) missing uniquestring in object: #{JSON.pretty_generate(object)}"
            end
            return
        end

        if object["mikuType"] == "NxDataBeacon" then
            if object["uuid"].nil? then
                raise "(error: 5e9abafa) missing uuid in object: #{JSON.pretty_generate(object)}"
            end
            if object["description"].nil? then
                raise "(error: 2cf4da17) missing description in object: #{JSON.pretty_generate(object)}"
            end
            if object["id"].nil? then
                raise "(error: ca7bd8a0) missing id in object: #{JSON.pretty_generate(object)}"
            end
            return
        end

        if object["mikuType"] == "NxLink" then
            if object["uuid"].nil? then
                raise "(error: 5e9abafa) missing uuid in object: #{JSON.pretty_generate(object)}"
            end
            if object["uuid1"].nil? then
                raise "(error: 5d38afd2) missing uuid1 in object: #{JSON.pretty_generate(object)}"
            end
            if object["uuid2"].nil? then
                raise "(error: ca7bd8a0) missing uuid2 in object: #{JSON.pretty_generate(object)}"
            end
            # We now need to ensure that the linked objects, if they exist, are Permanodes
            object1 = NxObjectIO::getObjectByUUIDOrNull(object["uuid1"])
            if object1 and !PolyFunctions::networkNodeTypes().include?(object1["mikuType"]) then
                raise "(error: e1564a30) Linked object is not linkable; link: #{JSON.pretty_generate(object)}; linked: #{JSON.pretty_generate(object1)}"
            end
            object2 = NxObjectIO::getObjectByUUIDOrNull(object["uuid2"])
            if object2 and !PolyFunctions::networkNodeTypes().include?(object2["mikuType"]) then
                raise "(error: e1564a30) Linked object is not linkable; link: #{JSON.pretty_generate(object)}; linked: #{JSON.pretty_generate(object2)}"
            end
            return
        end

        if object["mikuType"] == "NxNote" then
            if object["uuid"].nil? then
                raise "(error: 5e9abafa) missing uuid in object: #{JSON.pretty_generate(object)}"
            end
            if object["datetime"].nil? then
                raise "(error: 5d38afd2) missing datetime in object: #{JSON.pretty_generate(object)}"
            end
            if object["targetuuid"].nil? then
                raise "(error: ca7bd8a0) missing targetuuid in object: #{JSON.pretty_generate(object)}"
            end
            if object["text"].nil? then
                raise "(error: ca7bd8a0) missing text in object: #{JSON.pretty_generate(object)}"
            end
            return
        end

        raise "(error: d4fa1c3e) un-supported mikuType: #{JSON.pretty_generate(object)}"
    end

    # Fsck::fsckAll()
    def self.fsckAll()
        NxObjectIO::allObjects().each{|item|
            puts "fsck: #{JSON.pretty_generate(item)}"
            Fsck::fsckObject(item)
        }
        puts "fsck completed"
    end
end
