
# encoding: UTF-8

class IfcsClaims

    # IfcsClaims::saveClaim(claim)
    def self.saveClaim(claim)
        BTreeSets::set("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/ifcs-claims", "236EA361-84E5-4DC3-9077-20D173DC73A3", claim["uuid"], claim)
    end

    # IfcsClaims::issueClaimTypeProject(projectuuid, position)
    def self.issueClaimTypeProject(projectuuid, position)
        claim = {
            "uuid"        => SecureRandom.uuid,
            "type"        => "project",
            "projectuuid" => projectuuid,
            "position"    => position,
        }
        BTreeSets::set("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/ifcs-claims", "236EA361-84E5-4DC3-9077-20D173DC73A3", claim["uuid"], claim)
    end

    # IfcsClaims::issueClaimTypeItem(projectuuid, itemuuid, position)
    def self.issueClaimTypeItem(projectuuid, itemuuid, position)
        claim = {
            "uuid"        => SecureRandom.uuid,
            "type"        => "item",
            "projectuuid" => projectuuid,
            "itemuuid"    => itemuuid,
            "position"    => position
        }
        IfcsClaims::saveClaim(claim)
    end

    # IfcsClaims::getClaimByUuidOrNull(claimuuid)
    def self.getClaimByUuidOrNull(claimuuid)
        BTreeSets::getOrNull("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/ifcs-claims", "236EA361-84E5-4DC3-9077-20D173DC73A3", claimuuid)
    end

    # IfcsClaims::destroy(claimuuid)
    def self.destroy(claimuuid)
        BTreeSets::destroy("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/ifcs-claims", "236EA361-84E5-4DC3-9077-20D173DC73A3", claimuuid)
    end

    # IfcsClaims::claimDescription(claim)
    def self.claimDescription(claim)
        if claim["type"] == "project" then
            project = Projects::getProjectByUUIDOrNUll(claim["projectuuid"])
            return ( project ? "[project] #{project["description"]}" : "{unknown project at claim/project #{claim["uuid"]}}" )
        end
        if claim["type"] == "item" then
            project = Projects::getProjectByUUIDOrNUll(claim["projectuuid"])
            if project.nil? then
                return "{unknown project at claim/item #{claim["uuid"]}}"
            end
            item = Items::getItemOrNull(claim["projectuuid"], claim["itemuuid"])
            if item.nil? then
                return "{unknown item at claim/item #{claim["uuid"]}}"
            end
            return "[item] #{Items::itemBestDescription(item)}"
        end
        raise "error: 0f7a2c14-5443"
    end

    # IfcsClaims::claimsOrdered() # Array[ (ifcs claim, ordinal: Int) ]
    def self.claimsOrdered()
        BTreeSets::values("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/ifcs-claims", "236EA361-84E5-4DC3-9077-20D173DC73A3")
            .sort{|c1, c2| c1["position"] <=> c2["position"] }
    end

    # IfcsClaims::claimsOrderedWithOrdinal() # Array[ (ifcs claim, ordinal: Int) ]
    def self.claimsOrderedWithOrdinal()
        IfcsClaims::claimsOrdered()
            .map
            .with_index
            .to_a
    end

    # IfcsClaims::getClaimsOfTypeItemByUuids(projectuuid, itemuuid)
    def self.getClaimsOfTypeItemByUuids(projectuuid, itemuuid)
        BTreeSets::values("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/ifcs-claims", "236EA361-84E5-4DC3-9077-20D173DC73A3")
            .select{|claim| claim["type"] == "item" }
            .select{|claim| claim["projectuuid"] == projectuuid }
            .select{|claim| claim["itemuuid"] == itemuuid }
    end

    # IfcsClaims::getClaimsOfTypeProjectByUuid(projectuuid)
    def self.getClaimsOfTypeProjectByUuid(projectuuid)
        BTreeSets::values("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/ifcs-claims", "236EA361-84E5-4DC3-9077-20D173DC73A3")
           .select{|claim| claim["type"] == "project" }
            .select{|claim| claim["projectuuid"] == projectuuid }
    end

    # IfcsClaims::ifcsClaimToString(claim)
    def self.ifcsClaimToString(claim)
        uuid = claim["uuid"]
        isRunning = Runner::isRunning(uuid)
        runningSuffix = isRunning ? " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hour)" : ""
        position = claim["position"]
        ordinal = IfcsClaims::getClaimOrdinalOrNull(uuid)
        timeexpectation = DailyNegativeTimes::getItem24HoursTimeExpectationInHours(DAILY_TOTAL_ORDINAL_TIME_IN_HOURS, ordinal)
        timeInBank = Bank::total(uuid)
        "[ifcs] (pos: #{claim["position"]}, time exp.: #{timeexpectation.round(2)} hours, bank: #{(timeInBank.to_f/3600).round(2)} hours) #{IfcsClaims::claimDescription(claim)}#{runningSuffix}"
    end

    # IfcsClaims::claimMetric(ifcsclaim)
    def self.claimMetric(ifcsclaim)
        uuid = ifcsclaim["uuid"]
        return 1 if Runner::isRunning(uuid)
        return 0 if IfcsClaims::getClaimOrdinalOrNull(uuid) >= 4 # we only want 0 (Guardian) and 1, 2, 3
        timeInHours = Bank::total(uuid).to_f/3600
        timeInQuarterOfHours = timeInHours*4
        if timeInHours > 0 then
            0.70*Math.exp(-timeInHours)
        else
            0.70 + 0.05*(1-Math.exp(timeInHours))
        end
    end

    # Presents the current priority list of the caller and let them enter a number that is then returned
    # IfcsClaims::interactiveChoiceOfIfcsPosition()
    def self.interactiveChoiceOfIfcsPosition() # Float
        puts "Items"
        IfcsClaims::claimsOrdered()
            .each{|claim|
                uuid = claim["uuid"]
                puts "    - #{("%5.3f" % claim["position"])} #{IfcsClaims::claimDescription(claim)}"
            }
        LucilleCore::askQuestionAnswerAsString("position: ").to_f
    end

    # IfcsClaims::nextIfcsPosition()
    def self.nextIfcsPosition()
        IfcsClaims::claimsOrdered().map{|claim| claim["position"] }.max.ceil
    end

    # IfcsClaims::getClaimOrdinalOrNull(uuid)
    def self.getClaimOrdinalOrNull(uuid)
        IfcsClaims::claimsOrderedWithOrdinal()
            .select{|pair| pair[0]["uuid"] == uuid }
            .map{|pair| pair[1] }
            .first
    end

    # IfcsClaims::diveIfcsClaim(claim)
    def self.diveIfcsClaim(claim)
        loop {
            system("clear")
            puts IfcsClaims::ifcsClaimToString(claim).green
            puts JSON.pretty_generate(claim)
            puts "metric: #{IfcsClaims::claimMetric(claim)}".green
            options = [
                "destroy"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            break if option.nil?
            if option == "destroy" then
                IfcsClaims::destroy(claim["uuid"])
                return
            end
        }
    end
end
