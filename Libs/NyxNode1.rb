# encoding: UTF-8

=begin
NyxNode1 {
    "uuid"        : String
    "mikuType"    : "NyxNode1"
    "unixtime"    : Float
    "datetime"    : DateTime Iso 8601 UTC Zulu
    "description" : String
}
=end

class NyxNode1

    # --------------------------------------------
    # IO

    # NyxNode1::pathToObjectsRepository()
    def self.pathToObjectsRepository()
        "#{Config::userHomeDirectory()}/Galaxy/NxData/03-Nyx/01-Objects"
    end

    # NyxNode1::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = "#{NyxNode1::pathToObjectsRepository()}/#{item["uuid"]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NyxNode1::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{NyxNode1::pathToObjectsRepository()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NyxNode1::items()
    def self.items()
        folderpath = NyxNode1::pathToObjectsRepository()
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NyxNode1::destroy(uuid)
    def self.destroy(uuid)
        filepath = "#{NyxNode1::pathToObjectsRepository()}/#{uuid}.json"
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------
    # 

    # NyxNode1::interacrtivelyMakeNoteOrNull()
    def self.interacrtivelyMakeNoteOrNull()
        note = nil
        if LucilleCore::askQuestionAnswerAsBoolean("add note ? :") then
            note = CommonUtils::editTextSynchronously("")
        end
        note
    end

    # NyxNode1::issueUniqueStringOrNull()
    def self.issueUniqueStringOrNull()
        nil
    end

    # NyxNode1::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        note = NyxNode1::interacrtivelyMakeNoteOrNull()
        uniquestring = NyxNode1::issueUniqueStringOrNull()
        node = {
            "uuid"         => SecureRandom.uuid,
            "mikuType"     => "NyxNode1",
            "unixtime"     => Time.new.to_i,
            "datetime"     => Time.new.utc.iso8601,
            "description"  => description,
            "note"         => note,
            "uniquestring" => uniquestring
        }
        NyxNode1::commit(node)
        node
    end
end