
# encoding: UTF-8

class Cx

    # Cx::mikuTypes()
    def self.mikuTypes()
        ["CxAionPoint", "CxDx8Unit", "CxFile", "CxText", "CxUniqueString", "CxUrl"]
    end

    # Cx::interactivelySelectOneCxMikuTypeOrNull()
    def self.interactivelySelectOneCxMikuTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type", Cx::mikuTypes())
    end

    # Cx::interactivelyCreateNewCxForOwnerOrNull(owneruuid)
    def self.interactivelyCreateNewCxForOwnerOrNull(owneruuid)
        mikuType = Cx::interactivelySelectOneCxMikuTypeOrNull()
        return nil if mikuType.nil?
        if mikuType == "CxAionPoint" then
            return CxAionPoint::interactivelyIssueNewForOwnerOrNull(owneruuid)
        end
        if mikuType == "CxDx8Unit" then
            unitId = LucilleCore::askQuestionAnswerAsString("unitId (empty to abort): ")
            return nil if  unitId == ""
            return CxDx8Unit::issueNewForOwner(owneruuid, unitId)
        end
        if mikuType == "CxFile" then
            return CxFile::interactivelyIssueNewForOwnerOrNull(owneruuid)
        end
        if mikuType == "CxText" then
            return CxText::interactivelyIssueNewForOwner(owneruuid)
        end
        if mikuType == "CxUniqueString" then
            return CxUniqueString::interactivelyIssueNewForOwner(owneruuid)
        end
        if mikuType == "CxUrl" then
            return CxUrl::interactivelyIssueNewOrNullForOwner(owneruuid)
        end
        raise "(error: 0d26fe42-8669-4f33-9a09-aeecbd52c77c)"
    end

    # Cx::uuidToString(uuid)
    def self.uuidToString(uuid)

    end

    # Cx::access(uuid)
    def self.access(uuid)
        return if uuid.nil?
        puts "Cx::access(uuid)"
        LucilleCore::pressEnterToContinue()
    end
end
