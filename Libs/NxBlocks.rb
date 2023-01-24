# encoding: UTF-8

class NxBlocks

    # NxBlocks::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/NxBlock/#{uuid}.json"
    end

    # NxBlocks::items()
    def self.items()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxBlock")
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # NxBlocks::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = NxBlocks::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # NxBlocks::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = NxBlocks::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxBlocks::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxBlocks::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------------
    # Makers

    # NxBlocks::interactivelyIssueOrNull()
    def self.interactivelyIssueOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxBlock",
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "ordinal"     => ordinal
        }
        NxBlocks::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxBlocks::toString(item)
    def self.toString(item)
        "(block) (#{"%5.2f" % item["ordinal"]}) #{item["description"]}"
    end

    # NxBlocks::listingItems(cardinal)
    def self.listingItems(cardinal)
        NxBlocks::items()
            .sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
            .take(cardinal)
            .select{|item| BankExtended::stdRecoveredDailyTimeInHours(item["uuid"]) < 0.5 }
    end
end
