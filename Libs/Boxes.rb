=begin

A box is a collection of nodes of the Nyx network.
We use them to shape the network. 
The typical use is to contain nodes that are then linked to another one
The boxes live in XCacheSets.

box = {
    "uuid"             => SecureRandom.uuid,
    "creationunixtime" => Time.new.to_i,
    "name"             => name1,
}

=end

=begin
    XCacheSets::values(setuuid: String): Array[Value]
    XCacheSets::set(setuuid: String, valueuuid: String, value)
    XCacheSets::getOrNull(setuuid: String, valueuuid: String): nil | Value
    XCacheSets::destroy(setuuid: String, valueuuid: String)
=end

class Boxes

    # -------------------------------------------------------
    # Boxes

    # Boxes::issueBox(name1)
    def self.issueBox(name1)
        box = {
            "uuid"             => SecureRandom.uuid,
            "creationunixtime" => Time.new.to_i,
            "name"             => name1,
        }
        XCacheSets::set("879bc249-cba1-4197-aa86-3a1e32e3ea23", box["uuid"], box)
    end

    # Boxes::destroyBox(box)
    def self.destroyBox(box)
        XCacheSets::destroy("879bc249-cba1-4197-aa86-3a1e32e3ea23", box["uuid"])
    end

    # Boxes::boxes()
    def self.boxes()
        boxes = XCacheSets::values("879bc249-cba1-4197-aa86-3a1e32e3ea23")
        # At this point we do a little garbage collection, deleting boxes older than a day
        b1, b2 = boxes.partition{|box| (Time.new.to_f - box["creationunixtime"]) < 86400 }
        b2.each{|box| Boxes::destroyBox(box) }
        b1
    end

    # Boxes::interactivelySelectBoxPossiblyCreatedOrNull()
    def self.interactivelySelectBoxPossiblyCreatedOrNull()
        boxes = Boxes::boxes()
        if boxes.size > 0 then
            box = LucilleCore::selectEntityFromListOfEntitiesOrNull("box", boxes, lambda {|item| item["name"] })
            return box if box
        end
        if LucilleCore::askQuestionAnswerAsBoolean("create a new box ? ") then
            name1 = LucilleCore::askQuestionAnswerAsString("name (empty to abort): ")
            return nil if name1 == ""
            return Boxes::issueBox(name1)
        end
        nil
    end

    # -------------------------------------------------------
    # nodeuuids contained in boxes

    # Boxes::addNodeuuidToBox(box, nodeuuid)
    def self.addNodeuuidToBox(box, nodeuuid)
        # The nodeuuids are in a set named after the boxuuid
        XCacheSets::set("879bc249-cba1-4197-aa86-3a1e32e3ea23:#{box["uuid"]}", nodeuuid, nodeuuid)
    end

    # Boxes::addNodeuuidsToBox(box, nodeuuids)
    def self.addNodeuuidsToBox(box, nodeuuids)
        nodeuuids.each{|nodeuuid|
            Boxes::addNodeuuidToBox(box, nodeuuid)
        }
    end

    # Boxes::getNodeuuidsForBox(box)
    def self.getNodeuuidsForBox(box)
        XCacheSets::values("879bc249-cba1-4197-aa86-3a1e32e3ea23:#{box["uuid"]}")
            .uniq
    end

    # -------------------------------------------------------

    # Boxes::boxToString(box)
    def self.boxToString(box)
        "(box) #{box["name"]} (#{Boxes::getNodeuuidsForBox(box).size} items)"
    end

    # Boxes::printBoxes(shouldPrintExtraLineAfter)
    def self.printBoxes(shouldPrintExtraLineAfter)
        boxes = Boxes::boxes()
        return if boxes.empty?
        boxes.each{|box|
            puts Boxes::boxToString(box)
        }
        if shouldPrintExtraLineAfter then
            puts ""
        end
    end

    # Boxes::boxing(item)
    def self.boxing(item)
        box = Boxes::interactivelySelectBoxPossiblyCreatedOrNull()
        return if box.nil?
        action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["select linked(s) and add to box", "link to box contents"])
        return if action.nil?
        if action == "select linked(s) and add to box" then
            selected, _ = LucilleCore::selectZeroOrMore("linked", NxLink::related(item["uuid"]), [], lambda{ |item| LxFunction::function("toString", item) })
            nodeuuids = selected.map{|item| item["uuid"] }
            Boxes::addNodeuuidsToBox(box, nodeuuids)
        end
        if action == "link to box contents" then
            Boxes::getNodeuuidsForBox(box).each{|nodeuuid|
                NxLink::issue(item["uuid"], nodeuuid)
            }
        end
    end

end