# encoding: UTF-8

class TxStratospheres

    # TxStratospheres::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/TxStratosphere/#{uuid}.json"
    end

    # TxStratospheres::items()
    def self.items()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/TxStratosphere")
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # TxStratospheres::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = TxStratospheres::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # TxStratospheres::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = TxStratospheres::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # TxStratospheres::destroy(uuid)
    def self.destroy(uuid)
        filepath = TxStratospheres::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------------
    # Makers

    # TxStratospheres::interactivelyIssueOrNull()
    def self.interactivelyIssueOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "TxStratosphere",
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "ordinal"     => ordinal
        }
        TxStratospheres::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # TxStratospheres::toString(item)
    def self.toString(item)
        "(strat) (#{"%5.2f" % item["ordinal"]}) #{item["description"]}"
    end

    # TxStratospheres::listingItems()
    def self.listingItems()
        TxStratospheres::items()
            .sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
    end
end
