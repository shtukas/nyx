# encoding: UTF-8

class NxProjects

    # NxProjects::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/NxProject/#{uuid}.json"
    end

    # NxProjects::items()
    def self.items()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxProject")
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NxProjects::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = NxProjects::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxProjects::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NxProjects::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxProjects::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxProjects::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------------
    # Makers

    # NxProjects::interactivelyIssueOrNull()
    def self.interactivelyIssueOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
        tcId = NxWTimeCommitments::interactivelySelectItem()["uuid"]
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxProject",
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "tcId"        => tcId,
            "ordinal"     => ordinal
        }
        NxProjects::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxProjects::toString(item)
    def self.toString(item)
        "(project) (#{"%5.2f" % item["ordinal"]}) #{item["description"]}"
    end

    # NxProjects::listingItems(cardinal)
    def self.listingItems(cardinal)
        NxProjects::items()
            .sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
            .take(cardinal)
            .select{|item| BankExtended::stdRecoveredDailyTimeInHours(item["uuid"]) < 0.5 }
    end
end
