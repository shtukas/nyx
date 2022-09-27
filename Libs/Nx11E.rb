# encoding: UTF-8

class Nx11EListingMonitorUtils

    # We call Nx53 a Ax39Group or a NxTodo with a Nx11E/Ax39Engine

    # Nx11EListingMonitorUtils::nx53s()
    def self.nx53s()
        groups = NxTodos::items()
            .map{|item|
                if item["nx11e"]["type"] == "Ax39Group" then
                    item["nx11e"]["group"]
                else
                    nil
                end
            }
            .compact
            .reduce([]){|groups, group|
                groupIds = groups.map{|group| group["id"] }
                if groupIds.include?(group["id"]) then
                    groups
                else
                    groups + [group]
                end
            }
        simpleEngines = NxTodos::items()
            .map{|item|
                if item["nx11e"]["type"] == "Ax39Engine" then
                    item
                else
                    nil
                end
            }
            .compact
        groups + simpleEngines
    end

    # Nx11EListingMonitorUtils::nx53ToCompletionRatio(nx53)
    def self.nx53ToCompletionRatio(nx53)
        #puts "Nx11EListingMonitorUtils::nx53ToCompletionRatio(#{JSON.pretty_generate(nx53)})"
        if nx53["mikuType"] == "Ax39Group" then
            return Ax39::completionRatio(nx53["ax39"], nx53["account"])
        end
        if nx53["mikuType"] == "NxTodo" then
            return Ax39::completionRatio(nx53["nx11e"]["ax39"], nx53["nx11e"]["itemuuid"])
        end
        raise "(error: 80bf4429-79bb-4596-b8ea-beba8249d767)"
    end
end

class Nx11EGroupsUtils

    # Nx11EGroupsUtils::groups()
    def self.groups()
        NxTodos::items()
            .map{|item|
                if item["nx11e"]["type"] == "Ax39Group" then
                    item["nx11e"]["group"]
                else
                    nil
                end
            }
            .compact
            .reduce([]){|groups, group|
                groupIds = groups.map{|group| group["id"] }
                if groupIds.include?(group["id"]) then
                    groups
                else
                    groups + [group]
                end
            }
    end

    # Nx11EGroupsUtils::groupElementsInOrder(group)
    def self.groupElementsInOrder(group)
        NxTodos::items()
            .select{|item| item["nx11e"]["type"] == "Ax39Group" }
            .select{|item| item["nx11e"]["group"]["id"] == group["id"] }
            .sort{|i1, i2| i1["nx11e"]["position"] <=> i2["nx11e"]["position"] }
    end

    # Nx11EGroupsUtils::groupNextPosition(group)
    def self.groupNextPosition(group)
        elements = Nx11EGroupsUtils::groupElementsInOrder(group)
        return 1 if elements.empty?
        elements.map{|element| element["nx11e"]["position"] }.max.floor + 1
    end

    # Nx11EGroupsUtils::interactivelySelectGroupOrNull()
    def self.interactivelySelectGroupOrNull()
        groups = Nx11EGroupsUtils::groups()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("group", groups, lambda{|group| group["name"] })
    end

    # Nx11EGroupsUtils::makeNewGroupOrNull()
    def self.makeNewGroupOrNull()
        name1 = LucilleCore::askQuestionAnswerAsString("name: ")
        return nil if name1 == ""
        ax39 = Ax39::interactivelyCreateNewAxOrNull()
        {
            "id"       => SecureRandom.uuid,
            "mikuType" => "Ax39Group",
            "name"     => name1,
            "ax39"     => ax39,
            "account"  => SecureRandom.hex
        }
    end

    # Nx11EGroupsUtils::architectGroupOrNull()
    def self.architectGroupOrNull()
        puts "Select a group and if nothing you will get a chance to create a new one"
        group = Nx11EGroupsUtils::interactivelySelectGroupOrNull()
        return group if group
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to create a new group ? ", true) then
            return Nx11EGroupsUtils::makeNewGroupOrNull()
        end
        nil
    end

    # Nx11EGroupsUtils::interactivelyDecidePositionInThisGroup(group)
    def self.interactivelyDecidePositionInThisGroup(group)
        Nx11EGroupsUtils::groupElementsInOrder(group)
            .first(20)
            .each{|item| puts "    (#{"%7.3f" % item["nx11e"]["position"]}) #{item["description"]}" }
        position = LucilleCore::askQuestionAnswerAsString("position (empty for next): ")
        return position.to_f if (position != "")
        Nx11EGroupsUtils::groupNextPosition(group)
    end

    # Nx11EGroupsUtils::interactivelyMakeNewNx11EGroupOrNull()
    def self.interactivelyMakeNewNx11EGroupOrNull()
        group = Nx11EGroupsUtils::architectGroupOrNull()
        return nil if group.nil?
        position = Nx11EGroupsUtils::interactivelyDecidePositionInThisGroup(group)
        return {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "Nx11E",
            "type"     => "Ax39Group",
            "group"    => group,
            "position" => position
        }
    end

    # Nx11EGroupsUtils::groupDive(group)
    def self.groupDive(group)
        loop {
            elements = Nx11EGroupsUtils::groupElementsInOrder(group).first(20)
            element = LucilleCore::selectEntityFromListOfEntitiesOrNull("element", elements, lambda{|element| PolyFunctions::toString(element) })
            break if element.nil?
            PolyPrograms::itemLanding(element)
        }
    end

    # Nx11EGroupsUtils::groupsDive()
    def self.groupsDive()
        loop {
            group = Nx11EGroupsUtils::interactivelySelectGroupOrNull()
            break if group.nil?
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("group", ["dive", "start NxBall"])
            break if action.nil?
            if action == "dive" then
                Nx11EGroupsUtils::groupDive(group)
            end
            if action == "start NxBall" then
                NxBallsService::issue(SecureRandom.uuid, "group: #{group["name"]}", [group["account"]], 3600)
                break
            end
        }
    end

    # Nx11EGroupsUtils::bankaccountToItems(bankaccount)
    def self.bankaccountToItems(bankaccount)
        items = []
        NxTodos::items().each{|item|
            next if item["nx11e"]["type"] != "Ax39Group"
            next if item["nx11e"]["group"]["account"] != bankaccount
            items << item
        }
        items
    end
end

class Nx11E

    # Nx11E::types()
    def self.types()
        ["hot", "ordinal", "ondate", "Ax39Group", "Ax39Engine", "standard"]
    end

    # Makers

    # Nx11E::interactivelySelectTypeOrNull()
    def self.interactivelySelectTypeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type (none to abort):", Nx11E::types())
    end

    # Nx11E::makeOndate(datetime)
    def self.makeOndate(datetime)
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "Nx11E",
            "type"     => "ondate",
            "datetime" => datetime
        }
    end

    # Nx11E::makeHot()
    def self.makeHot()
        {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "Nx11E",
            "type"     => "hot",
            "unixtime" => Time.new.to_f
        }
    end

    # Nx11E::interactivelyCreateNewNx11EOrNull(itemuuid)
    def self.interactivelyCreateNewNx11EOrNull(itemuuid)
        type = Nx11E::interactivelySelectTypeOrNull()
        return nil if type.nil?
        if type == "hot" then
            return Nx11E::makeHot()
        end
        if type == "ordinal" then
            ordinal = LucilleCore::askQuestionAnswerAsString("ordinal (empty to abort): ")
            return nil if ordinal == ""
            return {
                "uuid"     => SecureRandom.uuid,
                "mikuType" => "Nx11E",
                "type"     => "ordinal",
                "ordinal"  => ordinal
            }
        end
        if type == "ondate" then
            datetime = CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
            return Nx11E::makeOndate(datetime)
        end
        if type == "Ax39Group" then
            return Nx11EGroupsUtils::interactivelyMakeNewNx11EGroupOrNull()
        end
        if type == "Ax39Engine" then
            ax39 = Ax39::interactivelyCreateNewAxOrNull()
            return nil if ax39.nil?
            return {
                "uuid"     => SecureRandom.uuid,
                "mikuType" => "Nx11E",
                "type"     => "Ax39Engine",
                "ax39"     => ax39,
                "itemuuid" => itemuuid
            }
        end
        if type == "standard" then
            return {
                "uuid"     => SecureRandom.uuid,
                "mikuType" => "Nx11E",
                "type"     => "standard",
                "unixtime" => Time.new.to_f
            }
        end
    end

    # Nx11E::interactivelySetANewEngineForItemOrNothing(item)
    def self.interactivelySetANewEngineForItemOrNothing(item)
        engine = Nx11E::interactivelyCreateNewNx11EOrNull(item["uuid"])
        return if engine.nil?
        ItemsEventsLog::setAttribute2(item["uuid"], "nx11e", engine)
    end

    # Functions

    # Nx11E::toString(nx11e)
    def self.toString(nx11e)
        if nx11e["mikuType"] != "Nx11E" then
            raise "(error: a06d321f-d66c-4909-bfb9-00a6787c0311) This function only takes Nx11Es, nx11e: #{nx11e}"
        end

        if nx11e["type"] == "hot" then
            return "(hot)"
        end

        if nx11e["type"] == "ordinal" then
            return "(ordinal: #{"%.2f" % nx11e["ordinal"]})"
        end

        if nx11e["type"] == "ondate" then
            return "(ondate: #{nx11e["datetime"][0, 10]})"
        end

        if nx11e["type"] == "Ax39Group" then
            group    = nx11e["group"]
            return "(ax39 group: #{group["name"]}, #{"%6.2f" % nx11e["position"]})"
        end

        if nx11e["type"] == "Ax39Engine" then
            return "(ax39)"
        end

        if nx11e["type"] == "standard" then
            return "(standard)"
        end

        raise "(error: b8adb3e1-eaee-4d06-afb4-bc0f3db0142b) nx11e: #{nx11e}"
    end

    # Nx11E::priorityOrNull(nx11e)
    # We return a null value when the nx11e should not be displayed
    def self.priorityOrNull(nx11e)
        shiftForUnixtimeOrdering = lambda {|unixtime|
            Math.atan(Time.new.to_f - unixtime).to_f/100
        }

        if nx11e["mikuType"] != "Nx11E" then
            raise "(error: a99fb12c-53a6-465a-8b87-14a85c58463b) This function only takes Nx11Es, nx11e: #{nx11e}"
        end

        if nx11e["type"] == "hot" then
            unixtime = nx11e["unixtime"]
            return 0.90 + shiftForUnixtimeOrdering.call(unixtime)
        end

        if nx11e["type"] == "ordinal" then
            return 0.85 -  Math.atan(nx11e["ordinal"]).to_f/100
        end

        if nx11e["type"] == "ondate" then
            return nil if (CommonUtils::today() < nx11e["datetime"][0, 10])
            return 0.70 + Math.atan(Time.new.to_f - DateTime.parse(nx11e["datetime"]).to_time.to_f).to_f/100
        end

        if nx11e["type"] == "Ax39Group" then

            thatIncreasingFunction = lambda{|x|
                # We want something decrasing on R, that goes to zero at -infinity
                # and is bounded (below) at +infinity
                (Math.atan(x)+Math::PI/2)/1000
            }

            group    = nx11e["group"]
            ax39     = group["ax39"]
            account  = group["account"]

            position = nx11e["position"]

            cr = Ax39::completionRatio(ax39, account)

            return nil if cr >= 1

            return 0.60 - (cr.to_f/10) - thatIncreasingFunction.call(position)
        end

        if nx11e["type"] == "Ax39Engine" then
            cr = Ax39::completionRatio(nx11e["ax39"], nx11e["itemuuid"])
            return nil if cr >= 1
            return 0.60 - cr.to_f/10
        end

        if nx11e["type"] == "standard" then
            unixtime = nx11e["unixtime"]
            return 0.40 + shiftForUnixtimeOrdering.call(unixtime)
        end

        raise "(error: 188c8d4b-1a79-4659-bd93-6d8e3ddfe4d1) nx11e: #{nx11e}"
    end
end