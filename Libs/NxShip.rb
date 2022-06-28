# encoding: UTF-8

class NxShip

    # NxShip::items()
    def self.items()
        Librarian::getObjectsByMikuType("NxShip")
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end

    # NxShip::destroy(uuid)
    def self.destroy(uuid)
        Bank::put("todo-done-count-afb1-11ac2d97a0a8", 1)
        Librarian::destroyClique(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxShip::interactivelyIssueNewOrNull(description = nil)
    def self.interactivelyIssueNewOrNull(description = nil)
        if description.nil? or description == "" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""
        else
            puts "description: #{description}"
        end

        uuid = SecureRandom.uuid

        nx111 = Nx111::interactivelyCreateNewNx111OrNull()

        unixtime    = Time.new.to_i
        datetime    = Time.new.utc.iso8601

        ax39 = Ax39::interactivelyCreateNewAx()

        item = {
          "uuid"        => uuid,
          "mikuType"    => "NxShip",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "ax39"        => ax39
        }
        Librarian::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxShip::toString(item)
    def self.toString(item)
        nx111String = item["nx111"] ? " (#{Nx111::toStringShort(item["nx111"])})" : ""
        "(ship) #{item["description"]}#{nx111String} #{Ax39::toString(item)} (rt: #{TxNumbersAcceleration::rt(item).round(2)})"
    end

    # NxShip::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(ship) #{item["description"]}"
    end

    # NxShip::itemShouldShow(item)
    def self.itemShouldShow(item)
        if item["ax39"]["type"] == "daily-time-commitment" then
            return TxNumbersAcceleration::rt(item) < item["ax39"]["hours"]
        end
        if item["ax39"]["type"] == "weekly-time-commitment" then
            return false if Time.new.wday == 5 # We don't show those on Fridays
            return TxNumbersAcceleration::combined_value(item) < item["ax39"]["hours"]
        end
        true
    end

    # NxShip::itemsForSection1()
    def self.itemsForSection1()
        NxShip::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end

    # NxShip::itemsForSection2()
    def self.itemsForSection2()
        NxShip::items()
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .select{|item| NxShip::itemShouldShow(item) }
    end

    # NxShip::nx20s()
    def self.nx20s()
        NxShip::items()
            .map{|item|
                {
                    "announce" => NxShip::toStringForSearch(item),
                    "unixtime" => item["unixtime"],
                    "payload"  => item
                }
            }
    end

    # --------------------------------------------------
    # Operations

    # NxShip::setAx39(item)
    def self.setAx39(item)
        item["ax39"] = Ax39::interactivelyCreateNewAx()
        Librarian::commit(item)
    end

    # NxShip::done(item)
    def self.done(item)
        puts NxShip::toString(item).green
        NxBallsService::close(item["uuid"], true)
    end

    # NxShip::dive()
    def self.dive()
        loop {
            system("clear")
            items = NxShip::items().sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("ship", items, lambda{|item| NxShip::toString(item) })
            break if item.nil?
            Landing::implementsNx111Landing(item)
        }
    end
end
