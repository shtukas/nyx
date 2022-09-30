
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

    # Cx22::bankaccountToItems(bankaccount)
    def self.bankaccountToItems(bankaccount)
        NxTodos::items()
            .select{|item| item["cx22"] and item["cx22"]["bankaccount"] == bankaccount }
    end

    # Cx22::interactivelySetANewContributionForItemOrNothing(item)
    def self.interactivelySetANewContributionForItemOrNothing(item)
        cx22 = Cx22::architectOrNull()
        return if cx22.nil?
        ItemsEventsLog::setAttribute2(item["uuid"], "cx22", cx22)
    end

    # Cx22::toString(cx22)
    def self.toString(cx22)
        "(#{cx22["groupname"]})"
    end

    # Cx22::toStringOrNull(cx22)
    def self.toStringOrNull(cx22)
        return nil if cx22.nil?
        "(#{cx22["groupname"]})"
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

    # Cx22::repDive(rep)
    def self.repDive(rep)
        loop {
            elements = Cx22::repToNxTodos(rep).first(20)
            element = LucilleCore::selectEntityFromListOfEntitiesOrNull("element", elements, lambda{|element| PolyFunctions::toString(element) })
            break if element.nil?
            PolyPrograms::itemLanding(element)
        }
    end

    # Cx22::repsDive()
    def self.repsDive()
        loop {
            group = Cx22::interactivelySelectCx22RepOrNull()
            break if group.nil?
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("group", ["dive", "start NxBall", "done for the day"])
            break if action.nil?
            if action == "dive" then
                Cx22::repDive(group)
            end
            if action == "start NxBall" then
                NxBallsService::issue(SecureRandom.uuid, "group: #{group["groupname"]}", [group["bankaccount"]], 3600)
                next
            end
            if action == "done for the day" then
                bankaccount = group["bankaccount"]
                BankAccountDoneForToday::setDoneToday(bankaccount)
                $CatalystAlfred1.mutateAfterBankAccountUpdate(bankaccount)
                next
            end
        }
    end

    # Cx22::repToNxTodos(rep) # Array[NxTodo]
    def self.repToNxTodos(rep)
        NxTodos::items()
            .select{|item| item["cx22"] and item["cx22"]["groupuuid"] == rep["groupuuid"] }
    end
end