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
    # Basic

    # NyxNode1::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = "#{Config::pathToDataCenter()}/NyxNode1/#{item["uuid"]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NyxNode1::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{Config::pathToDataCenter()}/NyxNode1/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NyxNode1::items()
    def self.items()
        folderpath = "#{Config::pathToDataCenter()}/NyxNode1"
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NyxNode1::destroy(uuid)
    def self.destroy(uuid)
        filepath = "#{Config::pathToDataCenter()}/NyxNode1/#{uuid}.json"
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------
    # 

    # NyxNode1::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        tx1 = Tx1::interactivelyMakeTx1()
        node = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "NyxNode1",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "tx1"         => tx1
        }
        NyxNode1::commit(node)
        node
    end
end