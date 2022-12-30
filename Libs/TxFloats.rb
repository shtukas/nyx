# encoding: UTF-8

class TxFloats

    # TxFloats::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/TxFloat/#{uuid}.json"
    end

    # TxFloats::items()
    def self.items()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/TxFloat")
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # TxFloats::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = TxFloats::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # TxFloats::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = TxFloats::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # TxFloats::destroy(uuid)
    def self.destroy(uuid)
        filepath = TxFloats::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------------
    # Makers

    # TxFloats::interactivelyIssueOrNull()
    def self.interactivelyIssueOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "TxFloat",
            "unixtime"    => Time.new.to_i,
            "description" => description
        }
        TxFloats::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # TxFloats::toString(item)
    def self.toString(item)
        "(float) #{item["description"]}"
    end

    # TxFloats::listingItems()
    def self.listingItems()
        TxFloats::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end
end
