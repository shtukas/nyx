
# encoding: UTF-8

class TxManualCountDowns

    # TxManualCountDowns::filepath(uuid)
    def self.filepath(uuid)
        "#{Config::pathToDataCenter()}/TxManualCountDown/#{uuid}.json"
    end

    # TxManualCountDowns::items()
    def self.items()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/TxManualCountDown")
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # TxManualCountDowns::commit(item)
    def self.commit(item)
        FileSystemCheck::fsck_MikuTypedItem(item, false)
        filepath = TxManualCountDowns::filepath(item["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # TxManualCountDowns::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = TxManualCountDowns::filepath(uuid)
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # TxManualCountDowns::destroy(uuid)
    def self.destroy(uuid)
        filepath = TxManualCountDowns::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # TxManualCountDowns::issueNewOrNull()
    def self.issueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        dailyTarget = LucilleCore::askQuestionAnswerAsString("daily target (empty to abort): ")
        return nil if dailyTarget == ""
        dailyTarget = dailyTarget.to_i
        item = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "TxManualCountDown",
            "description" => description,
            "dailyTarget" => dailyTarget,
            "date"        => CommonUtils::today(),
            "counter"     => dailyTarget,
            "lastUpdatedUnixtime" => nil
        }
        TxManualCountDowns::commit(item)
        item
    end

    # Data

    # TxManualCountDowns::listingItems()
    def self.listingItems()
        TxManualCountDowns::items().each{|item|
            if item["date"] != CommonUtils::today() then
                item["date"] = CommonUtils::today()
                item["counter"] = item["dailyTarget"]
                TxManualCountDowns::commit(item)
            end
        }
        TxManualCountDowns::items()
            .select{|item| item["counter"] > 0 }
            .select{|item| item["lastUpdatedUnixtime"].nil? or (Time.new.to_i - item["lastUpdatedUnixtime"]) > 3600 }
    end

    # Ops

    # TxManualCountDowns::performUpdate(item)
    def self.performUpdate(item)
        puts item["description"]
        count = LucilleCore::askQuestionAnswerAsString("#{item["description"]}: done count: ").to_i
        item["counter"] = item["counter"] - count
        item["lastUpdatedUnixtime"] = Time.new.to_i
        puts JSON.pretty_generate(item)
        TxManualCountDowns::commit(item)
    end

end
