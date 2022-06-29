
# encoding: UTF-8

class TxNumbersAcceleration

    # TxNumbersAcceleration::rt(item)
    def self.rt(item)
        XCache::getOrDefaultValue("zero-rt-6e6e6fbebbc5:#{item["uuid"]}", "0").to_f
    end

    # TxNumbersAcceleration::combined_value(item)
    def self.combined_value(item)
        XCache::getOrDefaultValue("combined-value-53a4f8ab8a64:#{item["uuid"]}", "0").to_f
    end

    # TxNumbersAcceleration::count(item)
    def self.count(item)
        XCache::getOrDefaultValue("task-count-a078bc6f:#{item["uuid"]}", "0").to_i
    end
end

if $RunNonEssentialThreads then
    Thread.new {
        sleep 10
        loop {
            (TxProjects::items()+TxTaskQueues::items()).each{|item|

                rt = BankExtended::stdRecoveredDailyTimeInHours(item["uuid"])
                XCache::set("zero-rt-6e6e6fbebbc5:#{item["uuid"]}", rt)

                cvalue = Bank::combinedValueOnThoseDays(item["uuid"], CommonUtils::dateSinceLastSaturday())
                XCache::set("combined-value-53a4f8ab8a64:#{item["uuid"]}", rt)

                count = Nx07::owneruuidToTaskuuids(item["uuid"]).size
                XCache::set("task-count-a078bc6f:#{item["uuid"]}", count)
            }
            sleep 600
        }
    }
end
