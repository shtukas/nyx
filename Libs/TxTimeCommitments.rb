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
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("time commitment", items, lambda{|item| TxTimeCommitments::toString(item) })
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
            end
            if option == "add time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                puts "Adding #{timeInHours.to_f} hours to #{PolyFunctions::toString(item).green}"
                Bank::put(item["uuid"], timeInHours.to_f*3600)
            end
        }
    end

    # TxTimeCommitments::interactivelyAddThisElementToOwner(element)
    def self.interactivelyAddThisElementToOwner(element)
        puts "TxTimeCommitments::interactivelyAddThisElementToOwner(#{JSON.pretty_generate(element)})"
        if element["mikuType"] != "NxTask" then
            puts "The operation TxTimeCommitments::interactivelyAddThisElementToOwner only works on NxTasks"
            LucilleCore::pressEnterToContinue()
            return
        end
        owner = TxTimeCommitments::architectOneOrNull()
        return if owner.nil?
        puts JSON.pretty_generate(owner)
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
end
