
# encoding: UTF-8

class DetachedRunning

    # DetachedRunning::issueNew2(description, startUnixtime, bankAccounts)
    def self.issueNew2(description, startUnixtime, bankAccounts)
        item = {
            "uuid"          => SecureRandom.uuid,
            "description"   => description,
            "startUnixtime" => startUnixtime,
            "bankAccounts"  => bankAccounts
        }
        BTreeSets::set(nil, "72ddaf05-e70e-4480-885c-06c00527025b", item["uuid"], item)
    end

    # DetachedRunning::items()
    def self.items()
        BTreeSets::values(nil, "72ddaf05-e70e-4480-885c-06c00527025b")
    end

    # DetachedRunning::done(item)
    def self.done(item)
        timespan = [Time.new.to_i - item["startUnixtime"], 3600*2].min
        item["bankAccounts"].each{|account|
            puts "Putting #{timespan} seconds into account: #{account}"
            Bank::put(account, timespan)
        }
        BTreeSets::destroy(nil, "72ddaf05-e70e-4480-885c-06c00527025b", item["uuid"])
    end

    # DetachedRunning::toString(item)
    def self.toString(item)
        "[detached running] #{item["description"]} (running for #{((Time.new.to_i - item["startUnixtime"]).to_f/3600).round(2)} hours)"
    end

    # DetachedRunning::ns16s()
    def self.ns16s()
        DetachedRunning::items()
        .map{|item|
            {
                "uuid"     => item["uuid"],
                "metric"   => ["ns:running", nil],
                "announce" => DetachedRunning::toString(item).gsub("[detached running]", "[detr]").green,
                "access"   => lambda{
                    if LucilleCore::askQuestionAnswerAsBoolean("stop ? : ") then
                        DetachedRunning::done(item)
                    end
                },
                "done"     => lambda { DetachedRunning::done(item) }
            }
        }
    end
end