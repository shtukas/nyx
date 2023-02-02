# encoding: UTF-8


class Engine

    # Engine::itemsForMikuType(mikuType)
    def self.itemsForMikuType(mikuType)
        ObjectStore1::databaseQuery("select * from objects where mikuType=?", [mikuType])
            .map{|object| ObjectStore1ItemObjectsTranslation::databaseObjectToItem(object) }
    end

    # Engine::listingItems()
    def self.listingItems()
        ObjectStore1::databaseQuery("select * from objects where field12=?", ["true"])
            .map{|object| ObjectStore1ItemObjectsTranslation::databaseObjectToItem(object) }
    end

    # Engine::the99Count()
    def self.the99Count()
        ObjectStore1::filepaths()
            .map{|filepath|
                count = nil
                db = SQLite3::Database.new(filepath)
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                db.execute("select count(*) as count from objects where mikuType=?", ["NxTodo"]) do |row|
                    count = row["count"]
                end
                db.close
                count
            }
            .inject(0, :+)
    end

    # Engine::itemIsListed(item)
    def self.itemIsListed(item)
        item["field12"] == "true"
    end

    # Engine::activateItemForListing(item, trajectory)
    def self.activateItemForListing(item, trajectory)
        return if ObjectStore1::getOrNull(item["uuid"], "field12") == "true"
        ObjectStore1::set(item["uuid"], "field12", "true")
        ObjectStore1::set(item["uuid"], "field13", JSON.generate(trajectory))
    end

    # Engine::disactivateListing(item)
    def self.disactivateListing(item)
        ObjectStore1::set(item["uuid"], "field7", 0)       # reset skipped until
        ObjectStore1::set(item["uuid"], "field8", "")      # remove any lock
        ObjectStore1::set(item["uuid"], "field12", "")     # remove listing flag
        ObjectStore1::set(item["uuid"], "field13", "null") # remove trajectory
    end

    # Engine::listingActivations()
    def self.listingActivations()

        Engine::itemsForMikuType("NxAnniversary")
            .select{|anniversary| Anniversaries::isOpenToAcknowledgement(anniversary) }
            .each{|item|
                next if Engine::itemIsListed(item)
                next if !DoNotShowUntil::isVisible(item)
                Engine::activateItemForListing(item, Engine::trajectory(Time.new.to_f, 6))
            }

        Engine::itemsForMikuType("NxTodo")
            .each{|item|
                next if Engine::itemIsListed(item)
                next if !DoNotShowUntil::isVisible(item)
                next if item["field2"] != "ondate"
                next if Time.new.to_s[0, 10] < item["datetime"][0, 10]
                Engine::activateItemForListing(item, Engine::trajectory(Time.new.to_f, 6))
            }

        Engine::itemsForMikuType("NxTodo")
            .each{|item|
                next if Engine::itemIsListed(item)
                next if !DoNotShowUntil::isVisible(item)
                next if item["field2"] != "triage"
                Engine::activateItemForListing(item, Engine::trajectory(Time.new.to_f, 24))
            }

        listedTodoSize = lambda {
            Engine::listingItems()
                .select{|item| item["mikuType"] == "NxTodo" }
                .size
        }
        if listedTodoSize.call() < 6 then
            item = Engine::itemsForMikuType("NxTodo")
                        .select{|item| !Engine::itemIsListed(item) }
                        .select{|item| DoNotShowUntil::isVisible(item) }
                        .select{|item| item["field2"] == "regular" }
                        .sample
            if item then
                Engine::activateItemForListing(item, Engine::trajectory(Time.new.to_f, 48))
            end
        end

        TxManualCountDowns::listingItems()
            .each{|item|
                next if Engine::itemIsListed(item)
                next if !DoNotShowUntil::isVisible(item)
                Engine::activateItemForListing(item, Engine::trajectory(Time.new.to_f, 2))
            }

        Engine::itemsForMikuType("Wave")
            .each{|item|
                next if (item["onlyOnDays"] and !item["onlyOnDays"].include?(CommonUtils::todayAsLowercaseEnglishWeekDayName()))
                next if Engine::itemIsListed(item)
                next if !DoNotShowUntil::isVisible(item)
                Engine::activateItemForListing(item, Engine::trajectory(Time.new.to_f, 18))
            }

        Engine::itemsForMikuType("NxTimeCommitment")
            .each{|item|
                next if Engine::itemsForMikuType("NxTimeCapsule").select{|capsule| capsule["field10"] == item["uuid"] }.size > 0
                next if (Time.new.to_i - item["resetTime"]) < 86400*7

                (0..6).each{|indx|
                    capsule = {
                        "uuid"        => SecureRandom.uuid,
                        "mikuType"    => "NxTimeCapsule",
                        "unixtime"    => Time.new.to_i,
                        "datetime"    => Time.new.utc.iso8601,
                        "field1"      => item["field3"].to_f/7,
                        "field10"     => item["uuid"]
                    }
                    puts JSON.pretty_generate(capsule)
                    ObjectStore1::commitItem(capsule)
                    Engine::activateItemForListing(capsule, Engine::trajectory(Time.new.to_f + indx*86400, 24))
                }

                item["resetTime"] = Time.new.to_i

                ObjectStore1::commitItem(item)
            }

        Engine::itemsForMikuType("NxTimeCapsule")
            .each{|item|
                next if Engine::itemIsListed(item)
                next if !DoNotShowUntil::isVisible(item)
                # Time capsules are issued by NxTimeCommitment, and are actived at that moment
                # This exists in case we create one manually.
                Engine::activateItemForListing(item, Engine::trajectory(Time.new.to_f, 24))
            }

        Engine::itemsForMikuType("NxDrop")
            .each{|item|
                next if Engine::itemIsListed(item)
                next if !DoNotShowUntil::isVisible(item)
                # Time capsules are issued by NxTimeCommitment, and are actived at that moment
                # This exists in case we create one manually.
                Engine::activateItemForListing(item, Engine::trajectory(Time.new.to_f, 24))
            }
    end

    # Engine::trajectory(activationunixtime, expectedTimeToCompletionInHours)
    def self.trajectory(activationunixtime, expectedTimeToCompletionInHours)
        {
            "activationunixtime"              => activationunixtime,
            "expectedTimeToCompletionInHours" => expectedTimeToCompletionInHours
        }
    end
end

