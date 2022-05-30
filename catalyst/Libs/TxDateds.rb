# encoding: UTF-8

class TxDateds

    # TxDateds::items()
    def self.items()
        Librarian::getObjectsByMikuType("TxDated")
    end

    # TxDateds::destroy(uuid)
    def self.destroy(uuid)
        Librarian::logicaldelete(uuid)
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

        nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems())
        return nil if nx111.nil?

        uuid       = SecureRandom.uuid
        unixtime   = Time.new.to_i

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxDated",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "iam"        => nx111,
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

        nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems())
        return nil if nx111.nil?

        uuid       = SecureRandom.uuid
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxDated",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "iam"         => nx111
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
          "iam"         => nx111,
        }
        Librarian::commit(item)
        item
    end

    # --------------------------------------------------
    # toString

    # TxDateds::toString(item)
    def self.toString(item)
        "(ondate) [#{item["datetime"][0, 10]}] #{item["description"]} (#{item["iam"]["type"]})"
    end

    # TxDateds::toStringForNS19(item)
    def self.toStringForNS19(item)
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
            puts "iam: #{item["iam"]}".yellow
            puts "date: #{item["datetime"][0, 10]}".yellow

            store = ItemStore.new()

            TxAttachments::itemsForOwner(uuid).each{|attachment|
                indx = store.register(attachment, false)
                puts "[#{indx.to_s.ljust(3)}] #{TxAttachments::toString(attachment)}" 
            }

            puts "access | date | description | iam | attachment | show json | transmute | universe | destroy (gg) | exit (xx)".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"
            break if command == "xx"

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                LxAction::action("landing", entity)
                next
            end

            if Interpreting::match("access", command) then
                EditionDesk::accessItem(item)
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
                nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfCatalystItems())
                next if nx111.nil?
                puts JSON.pretty_generate(nx111)
                if LucilleCore::askQuestionAnswerAsBoolean("confirm change ? ") then
                    item["iam"] = nx111
                    Librarian::commit(item)
                end
            end

            if Interpreting::match("attachment", command) then
                ox = TxAttachments::interactivelyIssueNewOrNullForOwner(item["uuid"])
                puts JSON.pretty_generate(ox)
                next
            end

            if Interpreting::match("show json", command) then
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

            if Interpreting::match("universe", command) then
                item["universe"] = Multiverse::interactivelySelectUniverse()
                Librarian::commit(item)
                next
            end

            if command == "gg" then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{TxDateds::toString(item)}' ? ", true) then
                    TxDateds::destroy(item["uuid"])
                    break
                end
                next
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
    # nx16s

    # TxDateds::ns16(item)
    def self.ns16(item)
        uuid = item["uuid"]
        {
            "uuid"     => uuid,
            "mikuType" => "NS16:TxDated",
            "announce" => TxDateds::toString(item),
            "TxDated"  => item
        }
    end

    # TxDateds::ns16s()
    def self.ns16s()
        TxDateds::items()
            .select{|item| item["datetime"][0, 10] <= CommonUtils::today() }
            .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            .map{|item| TxDateds::ns16(item) }
    end

    # --------------------------------------------------

    # TxDateds::nx20s()
    def self.nx20s()
        TxDateds::items().map{|item|
            {
                "announce" => TxDateds::toStringForNS19(item),
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
