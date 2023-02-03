
# encoding: UTF-8

class TxManualCountDowns

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
        ObjectStore1::commitItem(item)
        item
    end

    # Data

    # TxManualCountDowns::listingItems()
    def self.listingItems()
        Engine::itemsForMikuType("TxManualCountDown").each{|item|
            if item["date"] != CommonUtils::today() then
                item["date"] = CommonUtils::today()
                item["counter"] = item["dailyTarget"]
                ObjectStore1::commitItem(item)
            end
        }
        Engine::itemsForMikuType("TxManualCountDown")
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
        ObjectStore1::commitItem(item)
    end

    # TxManualCountDowns::access(item)
    def self.access(item)
        puts "> #{item["description"]}"
        donecount = LucilleCore::askQuestionAnswerAsString("done count: ").to_i
        remaincount = item["counter"] - donecount
        ObjectStore1::set(item["uuid"], "field3", remaincount)
        trajectory = Engine::trajectory(Time.new.to_f, 2)
        ObjectStore1::set(item["uuid"], "field13", JSON.generate(trajectory))
    end
end
