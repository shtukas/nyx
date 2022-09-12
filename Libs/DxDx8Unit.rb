
# encoding: UTF-8

class DxDx8Unit

    # ----------------------------------------------------------------------
    # Objects Management

    # DxDx8Unit::items()
    def self.items()
        TheIndex::mikuTypeToItems("DxDx8Unit")
    end

    # DxDx8Unit::interactivelyIssueNew()
    def self.interactivelyIssueNew()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        unitId = LucilleCore::askQuestionAnswerAsString("unitId (empty to abort): ")
        return nil if unitId == ""
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "DxDx8Unit")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "description", description)
        DxF1::setAttribute2(uuid, "unitId", unitId)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: dfd0d395-47d3-4e13-a51c-3dcbc473a2b2) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # DxDx8Unit::toString(item)
    def self.toString(item)
        "#{Stargate::formatTypeForToString("DxDx8Unit")} #{item["unitId"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # DxDx8Unit::access(item)
    def self.access(item)
        puts "DxDx8Unit::access has not been implemented yet"
        LucilleCore::pressEnterToContinue()
    end
end
