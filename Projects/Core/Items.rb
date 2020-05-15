
# encoding: UTF-8

class Items
    # Items::attachItemToProject(projectuuid, item)
    def self.attachItemToProject(projectuuid, item)
        # There is a copy of function in LucilleTxt/catalyst-objects-processing
        BTreeSets::set("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/items1", projectuuid, item["uuid"], item)
    end

    # Items::getItemOrNull(projectuuid, itemuuid)
    def self.getItemOrNull(projectuuid, itemuuid)
        BTreeSets::getOrNull("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/items1", projectuuid, itemuuid)
    end

    # Items::getItemsByCreationTime(projectuuid)
    def self.getItemsByCreationTime(projectuuid)
        BTreeSets::values("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/items1", projectuuid)
            .sort{|i1, i2| i1["creationtime"]<=>i2["creationtime"] }
    end

    # Items::detachItemFromProject(projectuuid, itemuuid)
    def self.detachItemFromProject(projectuuid, itemuuid)
        BTreeSets::destroy("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/items1", projectuuid, itemuuid)
    end

    # Items::itemBestDescription(item)
    def self.itemBestDescription(item)
        item["description"] || CatalystStandardTarget::targetToString(item["target"])
    end

    # Items::recastItemToOtherProject(projectuuid, itemuuid)
    def self.recastItemToOtherProject(projectuuid, itemuuid)
        item = Items::getItemOrNull(projectuuid, itemuuid)
        return if item.nil?
        # We need to choose a project, possibly a new one and add the item to it and remove the item from the original project
        targetproject = Projects::selectProjectFromExistingOrNewOrNull()
        return if targetproject.nil?
        return if targetproject["uuid"] == projectuuid
        Items::attachItemToProject(targetproject["uuid"], item)
        Items::detachItemFromProject(projectuuid, itemuuid)
    end

    # Items::openItem(item)
    def self.openItem(item)
        CatalystStandardTarget::openTarget(item["target"])
    end

    # Items::itemToString(project, item)
    def self.itemToString(project, item)
        itemuuid = item["uuid"]
        isRunning = Runner::isRunning(itemuuid)
        runningSuffix = isRunning ? " (running for #{(Runner::runTimeInSecondsOrNull(itemuuid).to_f/3600).round(2)} hour)" : ""
        "[item] (bank: #{(Bank::total(itemuuid).to_f/3600).round(2)} hours) [#{project["description"].yellow}] [#{item["target"]["type"]}] #{Items::itemBestDescription(item)}#{runningSuffix}"
    end

    # Items::itemMetric(projectuuid, itemuuid, projectmetric, indx)
    def self.itemMetric(projectuuid, itemuuid, projectmetric, indx)
        return 1 if Runner::isRunning(itemuuid)

        claims = IfcsClaims::getClaimsOfTypeItemByUuids(projectuuid, itemuuid)
        if claims.size > 0 then
            return claims.map{|ifcsclaim| IfcsClaims::claimMetric(ifcsclaim) }.max
        end

        projectmetric - indx.to_f/1000
    end

    # Items::diveItem(project, item)
    def self.diveItem(project, item)
        loop {
            system("clear")
            puts Items::itemToString(project, item).green
            puts JSON.pretty_generate([project, item])
            puts JSON.pretty_generate(IfcsClaims::getClaimsOfTypeItemByUuids(project["uuid"], item["uuid"]))
            puts "metric (project): #{Projects::projectMetric(project)}".green
            options = [
                "start",
                "open",
                "done",
                "set description",
                "dive ifcs claims",
                "add ifcs claim"
            ]
            if Runner::isRunning(item["uuid"]) then
                options.delete("start")
            else
                options.delete("stop")
            end
            if IfcsClaims::getClaimsOfTypeItemByUuids(project["uuid"], item["uuid"]).empty? then
                options.delete("dive ifcs claims")
            end
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            break if option.nil?
            if option == "start" then
                Runner::start(item["uuid"])
            end
            if option == "stop" then
                Runner::stop(item["uuid"])
            end
            if option == "open" then
                CatalystStandardTarget::openTarget(item["target"])
            end
            if option == "done" then
                Items::detachItemFromProject(project["uuid"], item["uuid"])
                return
            end
            if option == "set description" then
                item["description"] = CatalystCommon::editTextUsingTextmate(item["description"])
                Items::attachItemToProject(project["uuid"], item)
            end
            if option == "dive ifcs claims" then
                claims = IfcsClaims::getClaimsOfTypeItemByUuids(project["uuid"], item["uuid"])
                loop {
                    ifcsclaim = LucilleCore::selectEntityFromListOfEntitiesOrNull("claim", claims, lambda{|claim| IfcsClaims::ifcsClaimToString(claim) })
                    break if ifcsclaim.nil?
                    IfcsClaims::diveIfcsClaim(ifcsclaim)
                }
            end
            if option == "add ifcs claim" then
                position = IfcsClaims::interactiveChoiceOfIfcsPosition()
                IfcsClaims::issueClaimTypeItem(project["uuid"], item["uuid"], position)
            end
        }
    end

    # Items::receiveRunTimespan(projectuuid, itemuuid, timespan)
    def self.receiveRunTimespan(projectuuid, itemuuid, timespan)
        Bank::put(itemuuid, timespan, Utils::pingRetainPeriodInSeconds())
        Projects::receiveRunTimespan(projectuuid, timespan)
        IfcsClaims::getClaimsOfTypeItemByUuids(projectuuid, itemuuid).each{|claim|
            Bank::put(claim["uuid"], timespan, Utils::pingRetainPeriodInSeconds())
        }
    end
end
