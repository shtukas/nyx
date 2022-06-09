# encoding: UTF-8

class TxDateds

    # TxDateds::items()
    def self.items()
        Librarian::getObjectsByMikuType("TxDated")
    end

    # TxDateds::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxDateds::interactivelyCreateNewOrNull(description = nil)
    def self.interactivelyCreateNewOrNull(description = nil)
        if description.nil? or description == "" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""
        else
            puts "description: #{description}"
        end

        datetime = CommonUtils::interactivelySelectAUTCIso8601DateTimeOrNull()
        return nil if datetime.nil?

        uuid = SecureRandom.uuid

        nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems(), uuid)
        return nil if nx111.nil?

        unixtime   = Time.new.to_i

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxDated",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "nx111"       => nx111,
        }
        Librarian::commit(item)
        item
    end

    # TxDateds::interactivelyCreateNewTodayOrNull(description = nil)
    def self.interactivelyCreateNewTodayOrNull(description = nil)
        if description.nil? or description == "" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""
        else
            puts "description: #{description}"
        end

        uuid = SecureRandom.uuid

        nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems(), uuid)
        return nil if nx111.nil?

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxDated",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "nx111"       => nx111,
        }
        Librarian::commit(item)
        item
    end

    # TxDateds::issueViennaURL(url)
    def self.issueViennaURL(url)
        uuid        = SecureRandom.uuid
        description = "(vienna) #{url}"
        unixtime    = Time.new.to_i
        datetime    = Time.new.utc.iso8601

        nx111 = {
            "uuid" => SecureRandom.uuid,
            "type" => "url",
            "url"  => url
        }

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxDated",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "nx111"       => nx111,
        }
        Librarian::commit(item)
        item
    end

    # --------------------------------------------------
    # toString

    # TxDateds::toString(item)
    def self.toString(item)
        "(ondate) [#{item["datetime"][0, 10]}] #{item["description"]} (#{Nx111::toStringShort(item["nx111"])})"
    end

    # TxDateds::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(ondate) #{item["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxDateds::landing(item)
    def self.landing(item)

        loop {

            system("clear")
            
            uuid = item["uuid"]

            puts TxDateds::toString(item).green
            puts "uuid: #{uuid}".yellow
            puts "nx111: #{item["nx111"]}"
            puts "date: #{item["datetime"][0, 10]}".yellow

            store = ItemStore.new()

            notes = Ax1Text::itemsForOwner(uuid)
            if notes.size > 0 then
                puts "notes:"
                notes.each{|note|
                    indx = store.register(note, false)
                    puts "    [#{indx.to_s.ljust(3)}] #{Ax1Text::toString(note)}" 
                }
            end

            puts "access | date | description | iam | note | json | transmute | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("landing", entity)
                next
            end

            if Interpreting::match("access", command) then
                EditionDesk::accessItemWithI1asAttribute(item)
                next
            end

            if Interpreting::match("date", command) then
                datetime = CommonUtils::interactivelySelectAUTCIso8601DateTimeOrNull()
                next if datetime.nil?
                item["datetime"] = datetime
                Librarian::commit(item)
                next
            end

            if Interpreting::match("description", command) then
                description = CommonUtils::editTextSynchronously(item["description"]).strip
                next if description == ""
                item["description"] = description
                Librarian::commit(item)
                next
            end

            if Interpreting::match("iam", command) then
                nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems(), item["uuid"])
                next if nx111.nil?
                item["nx111"] = nx111
                Librarian::commit(item)
            end

            if Interpreting::match("note", command) then
                ox = Ax1Text::interactivelyIssueNewOrNullForOwner(item["uuid"])
                puts JSON.pretty_generate(ox)
                next
            end

            if Interpreting::match("json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                next
            end

            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxDateds::toString(item)}' ? ", true) then
                    TxDateds::destroy(item["uuid"])
                    break
                end
                next
            end

            if command == "transmute" then
                Transmutation::transmutation2(item, "TxDated")
                break
            end
        }
    end

    # TxDateds::dive()
    def self.dive()
        loop {
            system("clear")
            items = TxDateds::items().sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("dated", items, lambda{|item| TxDateds::toString(item) })
            break if item.nil?
            TxDateds::landing(item)
        }
    end

    # --------------------------------------------------
    # 

    # TxDateds::itemsForListing()
    def self.itemsForListing()
        TxDateds::items()
            .select{|item| item["datetime"][0, 10] <= CommonUtils::today() }
            .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
    end

    # --------------------------------------------------

    # TxDateds::nx20s()
    def self.nx20s()
        TxDateds::items().map{|item|
            {
                "announce" => TxDateds::toStringForSearch(item),
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
