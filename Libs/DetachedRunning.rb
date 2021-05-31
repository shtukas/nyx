
# encoding: UTF-8

class DetachedRunning

    # DetachedRunning::issueNew2(description, startUnixtime, type, payload)
    def self.issueNew2(description, startUnixtime, type, payload)
        raise "df3dc3a4-3962-42c2-92e8-e08c28a51081" if !["bank accounts", "counterx"].include?(type)
        item = {
            "uuid"          => SecureRandom.uuid,
            "description"   => description,
            "startUnixtime" => startUnixtime,
            "type"          => type,
            "payload"       => payload
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
        if item["type"] == "bank accounts" then
            item["payload"].each{|account|
                puts "Putting #{timespan} seconds into account: #{account}"
                Bank::put(account, timespan)
            }
        end
        if item["type"] == "counterx" then
            puts "putting #{timespan} seconds to CounterX"
        end
        $counterx.registerTimeInSeconds(timespan)
        BTreeSets::destroy(nil, "72ddaf05-e70e-4480-885c-06c00527025b", item["uuid"])
    end

    # DetachedRunning::toString(item)
    def self.toString(item)
        "[detached running] #{item["description"]} (running for #{((Time.new.to_i - item["startUnixtime"]).to_f/3600).round(2)} hours)"
    end

    # DetachedRunning::ns16s()
    def self.ns16s()
        DetachedRunning::items()
        .map
        .with_index{|item, indx|
            {
                "uuid"     => item["uuid"],
                "metric"   => ["ns:running", nil, indx],
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