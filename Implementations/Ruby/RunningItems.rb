# encoding: UTF-8

class RunningItems

    # RunningItems::items()
    def self.items()
        BTreeSets::values(nil, "88357686-97eb-4cf4-bdeb-7ede68281aaf")
    end

    # RunningItems::start(announce, bankAccounts)
    def self.start(announce, bankAccounts)
        item = {
            "uuid"         => SecureRandom.hex,
            "announce"     => announce,
            "start"        => Time.new.to_f,
            "bankAccounts" => bankAccounts,
        }
        BTreeSets::set(nil, "88357686-97eb-4cf4-bdeb-7ede68281aaf", item["uuid"], item)
        item
    end

    # RunningItems::displayLines()
    def self.displayLines()
        items = BTreeSets::values(nil, "88357686-97eb-4cf4-bdeb-7ede68281aaf")
        items.map{|item|
            "running: #{item["announce"]}".green
        }
    end

    # RunningItems::destroy(item)
    def self.destroy(item)
        BTreeSets::destroy(nil, "88357686-97eb-4cf4-bdeb-7ede68281aaf", item["uuid"])
    end

    # RunningItems::stopItem(item)
    def self.stopItem(item)
        timespan = Time.new.to_f - item["start"]
        timespan = [timespan, 3600*2].min
        item["bankAccounts"].each{|account|
            puts "putting #{timespan} seconds to account: #{account}"
            Bank::put(account, timespan)                
        }
        RunningItems::destroy(item)
    end

    # RunningItems::stop()
    def self.stop()
        item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", RunningItems::items(), lambda{|item| item["announce"] })
        return if item.nil?
        RunningItems::stopItem(item)
    end
end
