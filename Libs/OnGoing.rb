# encoding: UTF-8

class OnGoing

    # OnGoing::ns16s()
    def self.ns16s()

        #{
        #    "uuid"
        #    "unixtime"
        #    "description"
        #}

        BTreeSets::values(nil, "5f8226ce-87e0-45aa-8df7-15d36ec568d9")
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .map{|item|
                {
                    "uuid"     => item["uuid"],
                    "unixtime" => item["unixtime"],
                    "announce" => "[tody] #{item["description"]}",
                    "commands" => ["done"],
                    "interpreter" => lambda{|command|
                        if command == "done" then
                            BTreeSets::destroy(nil, "5f8226ce-87e0-45aa-8df7-15d36ec568d9", item["uuid"])
                        end
                    },
                    "run"      => lambda {
                        if LucilleCore::askQuestionAnswerAsBoolean("destroy ? ", true) then
                            BTreeSets::destroy(nil, "5f8226ce-87e0-45aa-8df7-15d36ec568d9", item["uuid"])
                        end  
                    }
                }
            }
    end

    # OnGoing::makeNewFromDescription(description)
    def self.makeNewFromDescription(description)
        uuid = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "description" => description
        }
        BTreeSets::set(nil, "5f8226ce-87e0-45aa-8df7-15d36ec568d9", uuid, item)
        BTreeSets::getOrNull(nil, "5f8226ce-87e0-45aa-8df7-15d36ec568d9", uuid)
    end

    # OnGoing::nx19s()
    def self.nx19s()
        []
    end
end
