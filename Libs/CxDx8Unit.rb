
# encoding: UTF-8

class CxDx8Unit

    # CxDx8Unit::items()
    def self.items()
        TheIndex::mikuTypeToItems("CxDx8Unit")
    end

    # CxDx8Unit::issueNewForOwner(owneruuid, unitId)
    def self.issueNewForOwner(owneruuid, unitId)
        uuid = SecureRandom.uuid
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "CxDx8Unit")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "owneruuid", owneruuid)
        DxF1::setAttribute2(uuid, "unitId", unitId)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 0f512f44-6d46-4f15-9015-ca4c7bfe6d9c) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # CxDx8Unit::toString(item)
    def self.toString(item)
        "(CxDx8Unit) #{item["unitId"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # CxDx8Unit::access(item)
    def self.access(item)
        unitId = item["unitId"]
        location = Dx8UnitsUtils::acquireUnit(unitId)
        if location.nil? then
            puts "I could not acquire the Dx8Unit. Aborting operation."
            LucilleCore::pressEnterToContinue()
            return
        end
        puts "location: #{location}"
        StargateCentral::ensureCentral()
        if LucilleCore::locationsAtFolder(location).size == 1 and LucilleCore::locationsAtFolder(location).first[-5, 5] == ".webm" then
            location2 = LucilleCore::locationsAtFolder(location).first
            if File.basename(location2).include?("'") then
                location3 = "#{File.dirname(location2)}/#{File.basename(location2).gsub("'", "-")}"
                FileUtils.mv(location2, location3)
                location2 = location3
            end
            location = location2
        end
        system("open '#{location}'")
        return
        LucilleCore::pressEnterToContinue()
    end
end
