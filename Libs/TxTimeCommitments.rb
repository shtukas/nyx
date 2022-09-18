# encoding: UTF-8

class TxTimeCommitments

    # --------------------------------------------------
    # IO

    # TxTimeCommitments::items()
    def self.items()
        TheIndex::mikuTypeToItems("TxTimeCommitment")
    end

    # TxTimeCommitments::destroy(uuid)
    def self.destroy(uuid)
        DxF1::deleteObject(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxTimeCommitments::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        datetime = CommonUtils::interactivelySelectDateTimeIso8601OrNullUsingDateCode()
        return nil if datetime.nil?
        uuid = SecureRandom.uuid

        ax39 = Ax39::interactivelyCreateNewAx()

        unixtime   = Time.new.to_i
        DxF1::setAttribute2(uuid, "uuid",         uuid)
        DxF1::setAttribute2(uuid, "mikuType",     "TxTimeCommitment")
        DxF1::setAttribute2(uuid, "unixtime",     unixtime)
        DxF1::setAttribute2(uuid, "datetime",     datetime)
        DxF1::setAttribute2(uuid, "description",  description)
        DxF1::setAttribute2(uuid, "ax39",         ax39)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 058e5a67-7fbe-4922-b638-2533428ee019) How did that happen ? 🤨"
        end
        item
    end

    # TxTimeCommitments::architectOneOrNull() # item or null
    def self.architectOneOrNull()
        item = TxTimeCommitments::interactivelySelectOneOrNull()
        return item if item
        if LucilleCore::askQuestionAnswerAsBoolean("Issue new TxTimeCommitment ? ") then
            return TxTimeCommitments::interactivelyCreateNewOrNull()
        end
        nil
    end

    # --------------------------------------------------
    # Data

    # TxTimeCommitments::toString(item)
    def self.toString(item)
        ax39str2 = Ax39::toString(item)
        doneForTodayStr = DoneForToday::isDoneToday(item["uuid"]) ? " (done for today)" : ""
        dnsustr = DoNotShowUntil::isVisible(item["uuid"]) ? "" : " (DoNotShowUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])})"
        "(tcpt) #{item["description"]} #{ax39str2}#{doneForTodayStr}#{dnsustr}"
    end

    # TxTimeCommitments::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(tcpt) #{item["description"]}"
    end

    # TxTimeCommitments::nx79s(owner, count) # Array[Nx79]
    def self.nx79s(owner, count)
        map = TimeCommitmentMapping::owneruuidToNx78(owner["uuid"])
        map.keys
            .sort{|uuid1, uuid2| map[uuid1] <=> map[uuid2] }
            .reduce([]){|selected, itemuuid|
                if selected.size >= count then
                    selected
                else
                    item = TheIndex::getItemOrNull(itemuuid)
                    if item then
                        nx79 = {
                            "item" => item,
                            "ordinal" => map[itemuuid]
                        }
                        selected + [nx79]
                    else
                        selected
                    end
                end
            }
    end

    # TxTimeCommitments::listingItems()
    def self.listingItems()
        TxTimeCommitments::items()
                .select{|item| DoNotShowUntil::isVisible(item["uuid"]) or NxBallsService::isPresent(item["uuid"]) }
                .select{|item| InternetStatus::itemShouldShow(item["uuid"]) or NxBallsService::isPresent(item["uuid"]) }
                .select{|item| Ax39forSections::itemShouldShow(item) or NxBallsService::isPresent(item["uuid"]) }
    end

    # --------------------------------------------------
    # Operations

    # TxTimeCommitments::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = TxTimeCommitments::items()
                    .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("TxTimeCommitment", items, lambda{|item| TxTimeCommitments::toString(item) })
    end

    # TxTimeCommitments::dive()
    def self.dive()
        loop {
            system("clear")
            items = TxTimeCommitments::items()
                        .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("time commitment", items, lambda{|item|  "#{TxTimeCommitments::toString(item)} [#{PolyFunctions::listingPriority(item).round(2)}]" })
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("TxTimeCommitment", ["start", "access" , "landing", "add time"])
            return if option.nil?
            if option == "start" then
                PolyActions::start(item)
            end
            if option == "landing" then
                PolyPrograms::itemLanding(item)
            end
            if option == "access" then
                CatalystListing::setContext(item["uuid"])
                PolyPrograms::catalystMainListing()
                break
            end
            if option == "add time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                puts "Adding #{timeInHours.to_f} hours to #{PolyFunctions::toString(item).green}"
                Bank::put(item["uuid"], timeInHours.to_f*3600)
            end
        }
    end

    # TxTimeCommitments::interactivelyAddThisElementToOwnerOrNothing(element)
    def self.interactivelyAddThisElementToOwnerOrNothing(element)
        puts "TxTimeCommitments::interactivelyAddThisElementToOwnerOrNothing(#{JSON.pretty_generate(element)})"
        if element["mikuType"] != "NxTask" then
            puts "The operation TxTimeCommitments::interactivelyAddThisElementToOwnerOrNothing only works on NxTasks"
            LucilleCore::pressEnterToContinue()
            return
        end
        owner = TxTimeCommitments::architectOneOrNull()
        return if owner.nil?

        puts PolyFunctions::toString(owner).green

        nx79s = TxTimeCommitments::nx79s(owner, CommonUtils::screenHeight()-2)
        nx79s
            .each{|nx79|
                e = nx79["item"]
                puts "(#{"%6.2f" % nx79["ordinal"]}) #{PolyFunctions::toString(e)}"
            }

        ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
        TimeCommitmentMapping::link(owner["uuid"], element["uuid"], ordinal)
        NxBallsService::close(element["uuid"], true)
    end

    # TxTimeCommitments::interactivelyProposeToAttachThisElementToOwner(element)
    def self.interactivelyProposeToAttachThisElementToOwner(element)
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to add to an owner ? ") then
            owner = TxTimeCommitments::architectOneOrNull()
            return if owner.nil?
            ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
            TimeCommitmentMapping::link(owner["uuid"], element["uuid"], ordinal)
        end
    end

    # TxTimeCommitments::landing(item)
    def self.landing(item)

        loop {

            return nil if item.nil?

            uuid = item["uuid"]
            item = DxF1::getProtoItemOrNull(uuid)
            return nil if item.nil?

            system("clear")

            puts PolyFunctions::toString(item)
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow

            puts ""
            puts "description | access | start | stop | edit | ax39 | do not show until | expose | destroy | nyx".yellow
            puts ""

            input = LucilleCore::askQuestionAnswerAsString("> ")
            next if input == ""

            # ordering: alphabetical

            if Interpreting::match("access", input) then
                PolyActions::access(item)
                next
            end

            if input == "ax39"  then
                return if item["mikuType"] != "TxTimeCommitment"
                ax39 = Ax39::interactivelyCreateNewAx()
                DxF1::setAttribute2(item["uuid"], "ax39",  ax39)
                next
            end

            if Interpreting::match("destroy", input) then
                PolyActions::destroyWithPrompt(item)
                return
            end

            if Interpreting::match("description", input) then
                PolyActions::editDescription(item)
                next
            end

            if input == "done for today" then
                DoneForToday::setDoneToday(item["uuid"])
                return
            end

            if Interpreting::match("do not show until", input) then
                datecode = LucilleCore::askQuestionAnswerAsString("datecode: ")
                return if datecode == ""
                unixtime = CommonUtils::codeToUnixtimeOrNull(datecode.gsub(" ", ""))
                return if unixtime.nil?
                PolyActions::stop(item)
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end

            if Interpreting::match("edit", input) then
                PolyFunctions::edit(item)
                return
            end

            if Interpreting::match("expose", input) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                return
            end

            if Interpreting::match("nyx", input) then
                Nyx::program()
                return
            end

            if Interpreting::match("start", input) then
                PolyActions::start(item)
                return
            end

            if Interpreting::match("stop", input) then
                PolyActions::stop(item)
                return
            end
        }

    end
end
