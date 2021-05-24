
# encoding: UTF-8

=begin

{
    "uuid"          : String
    "description"   : String
    "startUnixtime" : Integer
    "BankAccounts"  : Array[String]
}

=end

class DetachedRunning

    # DetachedRunning::issueNew(uuid, description, startUnixtime, bankAccounts)
    def self.issueNew(uuid, description, startUnixtime, bankAccounts)
        item = {
            "uuid"          => uuid,
            "description"   => description,
            "startUnixtime" => startUnixtime,
            "BankAccounts"  => bankAccounts
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
        item["BankAccounts"].each{|account|
            puts "Putting #{timespan} seconds into account: #{account}"
            Bank::put(account, timespan)
        }
        BTreeSets::destroy(nil, "72ddaf05-e70e-4480-885c-06c00527025b", item["uuid"])
    end

    # DetachedRunning::ns16s()
    def self.ns16s()
        DetachedRunning::items()
        .map
        .with_index{|item, indx|
            {
                "uuid"     => item["uuid"],
                "metric"   => ["ns:running", nil, indx],
                "announce" => "[detached running] #{item["description"]}".green,
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