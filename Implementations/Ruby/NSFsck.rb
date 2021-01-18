
# encoding: UTF-8

class NSFsck

    # NSFsck::processQuark(quark)
    def self.processQuark(quark)
        return true if quark["type"] == "line"
        return true if quark["type"] == "url"
        if quark["type"] == "aion-location" then
            roothash = quark["roothash"]
            puts "roothash: #{roothash}"
            operator = ElizabethX2.new()
            return AionFsck::structureCheckAionHash(operator, roothash)
        end
        if quark["type"] == "filesystem-unique-string" then
            puts "Finding filesystem-unique-string mark: #{quark["mark"]}"
            location = GalaxyFinder::uniqueStringToLocationOrNull(quark["mark"])
            if location.nil? then
                puts "Failing to find mark: #{quark["mark"]}"
                puts JSON.pretty_generate(quark)
                puts "[error: 76957559-8830-400d-b4fb-6e00081446a0]"
                return false
            end
            return true
        end
        puts "[error: e57fcfd1-f78c-4890-90e1-621df274eac7]"
        puts JSON.pretty_generate(quark)
        false
    end

    # NSFsck::processObject(object, runhash)
    def self.processObject(object, runhash)

        if object["nyxNxSet"] == "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4" then
            # Wave
            puts "fsck wave: #{object["uuid"]}"
            return true
        end
        
        if object["nyxNxSet"] == "d65674c7-c8c4-4ed4-9de9-7c600b43eaab" then
            # Quark
            puts "fsck quark: #{object["uuid"]}"
            return NSFsck::processQuark(object)
        end

        if object["nyxNxSet"] == "9644bd94-a917-445a-90b3-5493f5f53ffb" then
            # DataContainer
            puts "fsck data container: #{object["uuid"]}"
            return true
        end

        if object["nyxNxSet"] == "2ed4c63e-56df-4247-8f20-e8d220958226" then
            # DxThread
            puts "fsck DxThread: #{object["uuid"]}"
            return true
        end

        puts JSON.pretty_generate(object)
        puts "[error: eed35593-c378-4715-bbb7-5cbefbcd47ce]"
        false
    end

    # NSFsck::main(runhash)
    def self.main(runhash)
        NSCoreObjects::getAllObjects().each{|object|
            next if KeyValueStore::flagIsTrue(nil, "#{runhash}:#{object["uuid"]}")
            status = NSFsck::processObject(object, runhash)
            return false if !status
            KeyValueStore::setFlagTrue(nil, "#{runhash}:#{object["uuid"]}")
        }
        true
    end
end
