
# encoding: UTF-8

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'colorize'

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation, key)
    KeyValueStore::setFlagFalse(repositorylocation, key)
    KeyValueStore::flagIsTrue(repositorylocation, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Runner.rb"
=begin 
    Runner::isRunning(uuid)
    Runner::runTimeInSecondsOrNull(uuid) # null | Float
    Runner::start(uuid)
    Runner::stop(uuid) # null | Float
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Ping.rb"
=begin 
    Ping::put(uuid, weight)
    Ping::totalOverTimespan(uuid, timespanInSeconds)
    Ping::totalToday(uuid)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Bank.rb"
=begin 
    Bank::put(uuid, weight)
    Bank::total(uuid)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/QuarksCubesAndStarlightNodes.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Nyx.rb"

# -----------------------------------------------------------------------

class Items

    # Items::issueNewItem(projectname, projectuuid, description, target)
    def self.issueNewItem(projectname, projectuuid, description, target)
        item = {
            "nyxType"          => "todo-cc6d8717-98cf-4a7c-b14d-2261f0955b37",
            "uuid"             => SecureRandom.uuid,
            "creationUnixtime" => Time.new.to_f,
            "projectname"      => projectname,
            "projectuuid"      => projectuuid,
            "description"      => description,
            "target"           => target
        }
        Nyx::commitToDisk(item)
        item
    end

    # Items::selectProjectNameUuidPair()
    def self.selectProjectNameUuidPair()
        projectname = Items::selectProjectNameInteractivelyOrNull()
        projectuuid = nil
        if projectname.nil? then
            projectname = LucilleCore::askQuestionAnswerAsString("project name: ")
            projectuuid = SecureRandom.uuid
        else
            projectuuid = Items::projectname2projectuuidOrNUll(projectname)
            # We are not considering the case null
        end
        [projectname, projectuuid]
    end

    # Items::issueNewItemInteractivelyX1(description, target)
    def self.issueNewItemInteractivelyX1(description, target)
        projectname, projectuuid = Items::selectProjectNameUuidPair()
        item = {
            "nyxType"          => "todo-cc6d8717-98cf-4a7c-b14d-2261f0955b37",
            "uuid"             => SecureRandom.uuid,
            "creationUnixtime" => Time.new.to_f,
            "projectname"      => projectname,
            "projectuuid"      => projectuuid,
            "description"      => description,
            "target"           => target
        }
        Nyx::commitToDisk(item)
        item
    end

    # Items::itemBestDescription(item)
    def self.itemBestDescription(item)
        item["description"] || Quark::quarkToString(item["target"])
    end

    # Items::openItem(item)
    def self.openItem(item)
        Quark::openQuark(item["target"])
    end

    # Items::itemToString(item)
    def self.itemToString(item)
        itemuuid = item["uuid"]
        isRunning = Runner::isRunning(itemuuid)
        runningSuffix = isRunning ? " (running for #{(Runner::runTimeInSecondsOrNull(itemuuid).to_f/3600).round(2)} hour)" : ""
        "[todo item] (bank: #{(Bank::total(itemuuid).to_f/3600).round(2)} hours) [#{item["projectname"].yellow}] [#{item["target"]["type"]}] #{Items::itemBestDescription(item)}#{runningSuffix}"
    end

    # Items::itemReceivesRunTimespan(item, timespan, verbose = false)
    def self.itemReceivesRunTimespan(item, timespan, verbose = false)
        itemuuid = item["uuid"]
        projectuuid = item["projectuuid"]

        if verbose then
            puts "Bank: putting #{timespan.round(2)} secs into itemuuid: #{itemuuid}"
        end
        Bank::put(itemuuid, timespan)

        if verbose then
            puts "Bank: putting #{timespan.round(2)} secs into projectuuid: #{projectuuid}"
        end
        Bank::put(projectuuid, timespan)

        if verbose then
            puts "Ping: putting #{timespan.round(2)} secs into Todo application [uuid: ed4a67ee-c205-4ea4-a135-f10ea7782a7f]"
        end
        Ping::put("ed4a67ee-c205-4ea4-a135-f10ea7782a7f", timespan)
    end

    # Items::projectNames()
    def self.projectNames()
        Nyx::objects("todo-cc6d8717-98cf-4a7c-b14d-2261f0955b37")
            .map{|item| item["projectname"] }
            .uniq
            .sort
    end

    # Items::projectname2projectuuidOrNUll(projectname)
    def self.projectname2projectuuidOrNUll(projectname)
        projectuuid = KeyValueStore::getOrNull(nil, "440e3a2b-043c-4835-a59b-96deffb72f01:#{projectname}")
        return projectuuid if !projectuuid.nil?
        projectuuid = Nyx::objects("todo-cc6d8717-98cf-4a7c-b14d-2261f0955b37").select{|item| item["projectname"] == projectname }.first["projectuuid"]
        if !projectuuid.nil? then
            KeyValueStore::set(nil, "440e3a2b-043c-4835-a59b-96deffb72f01:#{projectname}", projectuuid)
        end
        projectuuid
    end

    # Items::selectProjectNameInteractivelyOrNull()
    def self.selectProjectNameInteractivelyOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", Items::projectNames().sort)
    end

    # Items::itemsForProjectName(projectname)
    def self.itemsForProjectName(projectname)
        projectuuid = Items::projectname2projectuuidOrNUll(projectname)
        return [] if projectuuid.nil?
        Nyx::objects("todo-cc6d8717-98cf-4a7c-b14d-2261f0955b37")
            .select{|item| item["projectuuid"] == projectuuid }
            .sort{|i1, i2| i1["creationUnixtime"]<=>i2["creationUnixtime"] }
    end

    # Items::projectsTimeDistribution()
    def self.projectsTimeDistribution()
        Items::projectNames().map{|projectname|
            projectuuid = Items::projectname2projectuuidOrNUll(projectname)
            {
                "projectname" => projectname,
                "projectuuid" => projectuuid,
                "timeInHours" => Bank::total(projectuuid).to_f/3600
            }
        }
    end

    # Items::updateItemProjectName(item)
    def self.updateItemProjectName(item)
        projectname = Items::selectProjectNameInteractivelyOrNull()
        projectuuid = nil
        if projectname.nil? then
            projectname = LucilleCore::askQuestionAnswerAsString("project name? ")
            return if projectname == ""
            projectuuid = SecureRandom.uuid
        else
            projectuuid = Items::projectname2projectuuidOrNUll(projectname)
            return if projectuuid.nil?
        end
        item["projectname"] = projectname
        item["projectuuid"] = projectuuid
        Nyx::commitToDisk(item)
    end

    # Items::recastAsStarlightNodeOrCubeContent(item) # Boolean # Indicates whether a promotion was acheived
    def self.recastAsStarlightNodeOrCubeContent(item) # Boolean # Indicates whether a promotion was acheived
        newowner = QuarksCubesAndStarlightNodesMakeAndOrSelectQuest::makeAndOrSelectSomethingOrNull()
        return false if newowner.nil?
        if newowner["nyxType"] == "starlight-node-8826cbad-e54e-4e78-bf7d-28c9c5019721" then
            node = newowner
            StarlightContents::issueClaimGivenNodeAndEntity(node, item["target"])
            return true
        end
        if newowner["nyxType"] == "cube-933c2260-92d1-4578-9aaf-cd6557c664c6" then
            clique = newowner
            clique = Nyx::getOrNull(clique["uuid"])
            clique["targets"] << item["target"]
            Nyx::commitToDisk(clique)
            return true
        end
        puts newowner
        raise "Todo: error: d089decd"
    end

    # Items::diveItem(item)
    def self.diveItem(item)
        loop {
            puts ""
            puts "uuid: #{item["uuid"]}"
            puts Items::itemToString(item).green
            puts "project time: #{Bank::total(item["projectuuid"].to_f/3600)} hours".green
            options = [
                "start",
                "open",
                "done",
                "set description",
                "recast",
                "push",
                "promote from Todo to Data"
            ]
            if Runner::isRunning(item["uuid"]) then
                options.delete("start")
            else
                options.delete("stop")
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
                Quark::openQuark(item["target"])
            end
            if option == "done" then
                Nyx::destroy(item["uuid"])
                return
            end
            if option == "set description" then
                item["description"] = CatalystCommon::editTextUsingTextmate(item["description"])
                Nyx::commitToDisk(item)
            end
            if option == "recast" then
                Items::updateItemProjectName(item)
            end
            if option == "push" then
                item["creationUnixtime"] = Time.new.to_f
                Nyx::commitToDisk(item)
            end
            if option == "promote from Todo to Data" then
                status = Items::recastAsStarlightNodeOrCubeContent(item)
                next if !status
                Nyx::destroy(item["uuid"])
                return
            end
        }
    end
end
