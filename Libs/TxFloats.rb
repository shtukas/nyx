# encoding: UTF-8

class TxFloats

    # -----------------------------------------
    # IO

    # TxFloats::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/TxFloat/#{uuid}.json"
    end

    # TxFloats::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/TxFloat")
            .select{|filepath| filepath[-5, 5] == ".json" }
    end

    # TxFloats::items()
    def self.items()
        TxFloats::filepaths()
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # TxFloats::getItemOrNull(uuid)
    def self.getItemOrNull(uuid)
        filepath = TxFloats::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # TxFloats::commit(item)
    def self.commit(item)
        filepath = TxFloats::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
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
