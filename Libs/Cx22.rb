
class Cx22

    # Cx22::makeCx22(groupuuid, description, bankaccount, ax39)
    def self.makeCx22(groupuuid, description, bankaccount, ax39)
        {
            "mikuType"    => "Cx22",
            "groupuuid"   => groupuuid,
            "groupname"   => description,
            "bankaccount" => bankaccount,
            "ax39"        => ax39
        }
    end

    # Cx22::makeNewOrNull()
    def self.makeNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        return nil if description == ""
        ax39 = Ax39::interactivelyCreateNewAx()
        Cx22::makeCx22(SecureRandom.uuid, description, SecureRandom.hex, ax39)
    end

    # Cx22::architectOrNull()
    def self.architectOrNull()
        puts "Select a group and if nothing you will get a chance to create a new one"
        group = Cx22::interactivelySelectCx22RepOrNull()
        return group if group
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to create a new group ? ", true) then
            return Cx22::makeNewOrNull()
        end
        nil
    end

    # Cx22::bankaccountToItemsInUnixtimeOrder(bankaccount)
    def self.bankaccountToItemsInUnixtimeOrder(bankaccount)
        NxTodos::items()
            .select{|item| item["cx22"] and item["cx22"]["bankaccount"] == bankaccount }
            .sort{|p1, p2| p1["unixtime"] <=> p2["unixtime"] }
    end

    # Cx22::interactivelySetANewContributionForItemOrNothing(item)
    def self.interactivelySetANewContributionForItemOrNothing(item)
        cx22 = Cx22::architectOrNull()
        return if cx22.nil?
        Items::setAttribute2(item["uuid"], "cx22", cx22)
    end

    # Cx22::toString(cx22)
    def self.toString(cx22)
        "(#{cx22["groupname"]})"
    end

    # Cx22::groupuuidToItemsWithPositionInPositionOrder(groupuuid) # Array[NxTodo] # with Cx22 and Cx23
    def self.groupuuidToItemsWithPositionInPositionOrder(groupuuid)
        NxTodos::items()
            .select{|item| item["cx22"] and item["cx22"]["groupuuid"] == groupuuid }
            .select{|item| item["cx23"] }
            .sort{|i1, i2| i1["cx23"]["position"] <=> i2["cx23"]["position"] }
    end

    # --------------------------------------------
    # Reps

    # Cx22::reps() # Array[Cx22]
    def self.reps()
        NxTodos::items()
            .map{|item| item["cx22"] }
            .compact
            .reduce([]){|groups, group|
                groupuuids = groups.map{|group| group["groupuuid"] }
                if groupuuids.include?(group["groupuuid"]) then
                    groups
                else
                    groups + [group]
                end
            }
    end

    # Cx22::interactivelySelectCx22RepOrNull()
    def self.interactivelySelectCx22RepOrNull()
        groups = Cx22::reps()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("group", groups, lambda{|rep| rep["groupname"]})
    end

    # Cx22::repElementsDive(rep)
    def self.repElementsDive(rep)
        loop {
            system("clear")
            elements = NxTodos::itemsInPositionOrderForGroup(rep).first(20)
            store = ItemStore.new()
            elements
                .each{|element|
                    store.register(element, false)
                    puts "#{store.prefixString()} #{PolyFunctions::toString(element)}"
                }

            puts ""
            puts "<n> | insert".yellow
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""

            if (indx = Interpreting::readAsIntegerOrNull(input)) then
                entity = store.get(indx)
                next if entity.nil?
                PolyActions::landing(entity)
                next
            end

            if Interpreting::match("insert", input) then
                description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
                next if description == ""
                uuid        = SecureRandom.uuid
                nx11e       = Nx11E::makeStandard()
                nx113nhash  = Nx113Make::interactivelyIssueNewNx113OrNullReturnDataBase1Nhash()
                cx22        = rep
                cx23        = nil
                position = LucilleCore::askQuestionAnswerAsString("position (empty for none): ")
                if position != "" then
                    position = position.to_f
                    cx23 = Cx23::makeCx23(rep["groupuuid"], position)
                end
                item = {
                    "uuid"        => uuid,
                    "mikuType"    => "NxTodo",
                    "unixtime"    => Time.new.to_i,
                    "datetime"    => Time.new.utc.iso8601,
                    "description" => description,
                    "nx113"       => nx113nhash,
                    "nx11e"       => nx11e,
                    "cx22"        => cx22,
                    "cx23"        => cx23
                }
                FileSystemCheck::fsckItemErrorArFirstFailure(item, SecureRandom.hex, true)
                Items::putItem(item)
                next
            end
        }
    end

    # Cx22::repDive(rep)
    def self.repDive(rep)
        loop {
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("rep", ["elements dive", "start NxBall", "done for the day", "un-{done for the day}", "expose", "completion ratio", "add time"])
            break if action.nil?
            if action == "elements dive" then
                Cx22::repElementsDive(rep)
            end
            if action == "start NxBall" then
                NxBallsService::issue(SecureRandom.uuid, "rep: #{rep["groupname"]}", [rep["bankaccount"]], 3600)
                next
            end
            if action == "done for the day" then
                bankaccount = rep["bankaccount"]
                BankAccountDoneForToday::setDoneToday(bankaccount)
                next
            end
            if action == "un-{done for the day}" then
                bankaccount = rep["bankaccount"]
                BankAccountDoneForToday::setUnDoneToday(bankaccount)
                next
            end
            if action == "expose" then
                puts JSON.pretty_generate(rep)
                LucilleCore::pressEnterToContinue()
                next
            end
            if action == "completion ratio" then
                puts JSON.pretty_generate(rep)
                ax39     = rep["ax39"]
                account  = rep["bankaccount"]
                cr = Ax39::completionRatio(ax39, account)
                puts "completion ratio: #{cr}"
                LucilleCore::pressEnterToContinue()
                next
            end
            if action == "add time" then
                timeInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                time = timeInHours*3600
                puts "Adding #{time} seconds to #{rep["bankaccount"]}"
                Bank::put(rep["bankaccount"], time)
                $CatalystGroupMonitor1.rebuildLx13sFromScratch()
                next
            end
        }
    end

    # Cx22::repsDive()
    def self.repsDive()
        loop {
            rep = Cx22::interactivelySelectCx22RepOrNull()
            return if rep.nil?
            Cx22::repDive(rep)
        }
    end

    # --------------------------------------------
    # Lx13s

    # Cx22::getLx13s()
    def self.getLx13s()
        Cx22::reps()
            .map{|rep|
                rep["cr"] = Ax39::completionRatio(rep["ax39"], rep["bankaccount"])
                rep
            }
    end

    # Cx22::getNonDoneForTodayRepWithLowersCRBelow1OrNull()
    def self.getNonDoneForTodayRepWithLowersCRBelow1OrNull()
        Cx22::getLx13s()
            .select{|rep| !BankAccountDoneForToday::isDoneToday(rep["bankaccount"])}
            .select{|rep| rep["cr"] < 1}
            .sort{|r1, r2| r1["cr"] <=> r2["cr"] }
            .first
    end
end