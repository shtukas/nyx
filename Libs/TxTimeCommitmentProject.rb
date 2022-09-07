# encoding: UTF-8

class TxTimeCommitmentProjects

    # --------------------------------------------------
    # IO

    # TxTimeCommitmentProjects::items()
    def self.items()
        TheIndex::mikuTypeToItems("TxTimeCommitmentProject")
    end

    # TxTimeCommitmentProjects::destroy(uuid)
    def self.destroy(uuid)
        DxF1::deleteObjectLogically(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxTimeCommitmentProjects::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        datetime = CommonUtils::interactivelySelectDateTimeIso8601OrNullUsingDateCode()
        return nil if datetime.nil?
        uuid = SecureRandom.uuid

        if LucilleCore::askQuestionAnswerAsBoolean("Singleton item ? ") then
            cx = Cx::interactivelyCreateNewCxForOwnerOrNull(uuid)
            nx112 = cx ? cx["uuid"] : nil
        else
            puts "You have chosen to build an owner, not asking for contents"
            nx112 = nil
        end

        ax39 = Ax39::interactivelyCreateNewAx()

        unixtime   = Time.new.to_i
        DxF1::setAttribute2(uuid, "uuid",         uuid)
        DxF1::setAttribute2(uuid, "mikuType",     "TxTimeCommitmentProject")
        DxF1::setAttribute2(uuid, "unixtime",     unixtime)
        DxF1::setAttribute2(uuid, "datetime",     datetime)
        DxF1::setAttribute2(uuid, "description",  description)
        DxF1::setAttribute2(uuid, "nx112",        nx112)
        DxF1::setAttribute2(uuid, "ax39",         ax39)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 058e5a67-7fbe-4922-b638-2533428ee019) How did that happen ? 🤨"
        end
        item
    end

    # TxTimeCommitmentProjects::architectOneOrNull() # item or null
    def self.architectOneOrNull()
        item = TxTimeCommitmentProjects::interactivelySelectOneOrNull()
        return item if item
        if LucilleCore::askQuestionAnswerAsBoolean("Issue new TxTimeCommitmentProject ? ") then
            return TxTimeCommitmentProjects::interactivelyCreateNewOrNull()
        end
        nil
    end

    # --------------------------------------------------
    # Data

    # TxTimeCommitmentProjects::toString(item)
    def self.toString(item)
        ax39str2 = Ax39::toString(item)
        doneForTodayStr = DoneForToday::isDoneToday(item["uuid"]) ? " (done for today)" : ""
        dnsustr = DoNotShowUntil::isVisible(item["uuid"]) ? "" : " (DoNotShowUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])})"
        "(tcpt) #{item["description"]} #{ax39str2}#{doneForTodayStr}#{dnsustr}"
    end

    # TxTimeCommitmentProjects::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(tcpt) #{item["description"]}"
    end

    # TxTimeCommitmentProjects::listingItems()
    def self.listingItems()
        TxTimeCommitmentProjects::items()
            .select{|item| Ax39forSections::itemShouldShow(item) }
            .sort{|i1, i2| Ax39forSections::orderingValue(i1) <=> Ax39forSections::orderingValue(i2) }
    end

    # TxTimeCommitmentProjects::nx79s(owner, count) # Array[Nx79]
    def self.nx79s(owner, count)
        map = OwnerItemsMapping::owneruuidToNx78(owner["uuid"])
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

    # TxTimeCommitmentProjects::interactivelySelectOneOrNull()
    def self.interactivelySelectOneOrNull()
        items = TxTimeCommitmentProjects::items()
                    .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("TxTimeCommitmentProject", items, lambda{|item| TxTimeCommitmentProjects::toString(item) })
    end

    # TxTimeCommitmentProjects::access(item, mode) # mode = "access" or "doubleDot"
    def self.access(item, mode)
        puts "TxTimeCommitmentProjects::access(#{JSON.pretty_generate(item)}, #{mode})"

        hasElements = OwnerItemsMapping::owneruuidToNx78(item["uuid"]).size > 0

        if item["nx112"] and hasElements then
            aspect = LucilleCore::selectEntityFromListOfEntitiesOrNull("aspect", ["carrier", "elements listing"])
            return if aspect.nil?
            if aspect == "carrier" then
                if mode == "doubleDot" then
                    PolyActions::start(item)
                end
                Cx::access(item["nx112"])
            end
            if aspect == "elements listing" then
                PolyPrograms::timeCommitmentProgram(item)
            end
        end

        if item["nx112"] and !hasElements then
            if mode == "doubleDot" then
                PolyActions::start(item)
            end
            Cx::access(item["nx112"])
        end

        if item["nx112"].nil? and hasElements then
            PolyPrograms::timeCommitmentProgram(item)
        end

        if item["nx112"].nil? and !hasElements then
            PolyPrograms::timeCommitmentProgram(item)
        end
    end

    # TxTimeCommitmentProjects::dive()
    def self.dive()
        loop {
            system("clear")
            items = TxTimeCommitmentProjects::items().sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("dated", items, lambda{|item| TxTimeCommitmentProjects::toString(item) })
            break if item.nil?
            PolyPrograms::landing(item)
        }
    end

    # TxTimeCommitmentProjects::interactivelyAddThisElementToOwner(element)
    def self.interactivelyAddThisElementToOwner(element)
        puts "TxTimeCommitmentProjects::interactivelyAddThisElementToOwner(#{JSON.pretty_generate(element)})"
        if element["mikuType"] != "NxTask" then
            puts "The operation TxTimeCommitmentProjects::interactivelyAddThisElementToOwner only works on NxTasks"
            LucilleCore::pressEnterToContinue()
            return
        end
        owner = TxTimeCommitmentProjects::architectOneOrNull()
        return if owner.nil?
        puts JSON.pretty_generate(owner)
        ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
        OwnerItemsMapping::link(owner["uuid"], element["uuid"], ordinal)
        NxBallsService::close(element["uuid"], true)
    end

    # TxTimeCommitmentProjects::interactivelyProposeToAttachThisElementToOwner(element)
    def self.interactivelyProposeToAttachThisElementToOwner(element)
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to add to an owner ? ") then
            owner = TxTimeCommitmentProjects::architectOneOrNull()
            return if owner.nil?
            ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
            OwnerItemsMapping::link(owner["uuid"], element["uuid"], ordinal)
        end
    end
end
