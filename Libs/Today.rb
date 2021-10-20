# encoding: UTF-8

class Today

    # Today::ns16s()
    def self.ns16s()

        #{
        #    "uuid"
        #    "unixtime"
        #    "description"
        #}

        BTreeSets::values(nil, "b153bd30-0582-4019-963a-68b01fb4bb7c")
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .map{|item|
                {
                    "uuid"     => item["uuid"],
                    "unixtime" => item["unixtime"],
                    "announce" => "[tody] #{item["description"]}",
                    "run"      => lambda {
                        if LucilleCore::askQuestionAnswerAsBoolean("destroy ? ", true) then
                            BTreeSets::destroy(nil, "b153bd30-0582-4019-963a-68b01fb4bb7c", item["uuid"])
                        end  
                    }
                }
            }
    end

    # Today::makeNewFromDescription(description)
    def self.makeNewFromDescription(description)
        uuid = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "description" => description
        }
        BTreeSets::set(nil, "b153bd30-0582-4019-963a-68b01fb4bb7c", uuid, item)
        BTreeSets::getOrNull(nil, "b153bd30-0582-4019-963a-68b01fb4bb7c", uuid)
    end

    # Today::nx19s()
    def self.nx19s()
        []
    end
end
