
# encoding: UTF-8

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
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

require 'colorize'

class Items

    # Items::itemBestDescription(item)
    def self.itemBestDescription(item)
        item["description"] || CatalystStandardTargets::targetToString(item["target"])
    end

    # Items::openItem(item)
    def self.openItem(item)
        CatalystStandardTargets::openTarget(item["target"])
    end

    # Items::itemToString(item)
    def self.itemToString(item)
        itemuuid = item["uuid"]
        isRunning = Runner::isRunning(itemuuid)
        runningSuffix = isRunning ? " (running for #{(Runner::runTimeInSecondsOrNull(itemuuid).to_f/3600).round(2)} hour)" : ""
        "[todo item] (bank: #{(Bank::total(itemuuid).to_f/3600).round(2)} hours) [#{item["projectname"].yellow}] [#{item["target"]["type"]}] #{Items::itemBestDescription(item)}#{runningSuffix}"
    end

    # Items::diveItem(item)
    def self.diveItem(item)
        loop {
            system("clear")
            puts "uuid: #{item["uuid"]}"
            puts Items::itemToString(item).green
            puts "ifcs claims:"
            puts JSON.pretty_generate(InFlightControlSystem::getClaimsByItemUUID(item["uuid"]))
            puts "project time: #{Bank::total(item["projectuuid"].to_f/3600)} hours".green
            options = [
                "start",
                "open",
                "done",
                "set description",
                "send target to a datapoint at starlight (and done item)",
                "attach target to starlight node (and done item)"
            ]
            if Runner::isRunning(item["uuid"]) then
                options.delete("start")
            else
                options.delete("stop")
            end
            if InFlightControlSystem::getClaimsByItemUUID(item["uuid"]).empty? then
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
                CatalystStandardTargets::openTarget(item["target"])
            end
            if option == "done" then
                Items::destroy(item["uuid"])
                return
            end
            if option == "set description" then
                item["description"] = CatalystCommon::editTextUsingTextmate(item["description"])
                Items::save(item)
            end
            if option == "send target to a datapoint at starlight (and done item)" then
                starlightnode = StartlightNodes::selectNodePossiblyMakeANewOneOrNull()
                next if starlightnode.nil?
                datapoints = StarlightOwnershipClaims::getDataEntitiesForNode(starlightnode)
                                .select{|dataentity| dataentity["catalystType"] == "catalyst-type:datapoint" }
                if datapoints.size == 0 then
                    puts "I could not find data points fot this node. Aborting operation."
                    LucilleCore::pressEnterToContinue()
                    next
                end
                datapoint = DataPoints::selectDataPointFromGivenSetOfDatPointsOrMakeANewOneOrNull(datapoints)
                next if datapoint.nil?
                target = item["target"]
                datapoint["targets"] << target # Adding the todo item to the datapoint target.
                # datapoint can now be sent to disk
                DataPoints::save(datapoint)
            end
            if option == "attach target to starlight node (and done item)" then
                starlightnode = StartlightNodes::selectNodePossiblyMakeANewOneOrNull()
                puts JSON.pretty_generate(starlightnode)
                next if starlightnode.nil?
                claim = StarlightOwnershipClaims::issueClaimGivenNodeAndCatalystStandardTarget(starlightnode, target)
                puts JSON.pretty_generate(claim)
            end
        }
    end

    # Items::receiveRunTimespan(item, timespan, verbose = false)
    def self.receiveRunTimespan(item, timespan, verbose = false)
        itemuuid = item["uuid"]
        projectuuid = item["projectuuid"]
        if verbose then
            puts "Bank: putting #{timespan} into itemuuid: #{itemuuid}"
        end
        Bank::put(itemuuid, timespan)
        if verbose then
            puts "Bank: putting #{timespan} into projectuuid: #{projectuuid}"
        end
        Bank::put(projectuuid, timespan)
        InFlightControlSystem::getClaimsByItemUUID(itemuuid).each{|claim|
            if verbose then
                puts "Bank: putting #{timespan} into claimuuid: #{claim["uuid"]}"
            end
            Bank::put(claim["uuid"], timespan)
        }
    end

    # Items::pathToRepository()
    def self.pathToRepository()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Todo/items2"
    end

    # Items::save(item)
    def self.save(item)
        filepath = "#{Items::pathToRepository()}/#{item["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(item)) }
    end

    # Items::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{Items::pathToRepository()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Items::destroy(itemuuid)
    def self.destroy(itemuuid)
        filepath = "#{Items::pathToRepository()}/#{itemuuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # Items::items()
    def self.items()
        Dir.entries(Items::pathToRepository())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{Items::pathToRepository()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # Items::projectNames()
    def self.projectNames()
        Items::items().map{|item| item["projectname"] }.uniq.sort
    end

    # Items::projectname2projectuuidOrNUll(projectname)
    def self.projectname2projectuuidOrNUll(projectname)
        projectuuid = KeyValueStore::getOrNull(nil, "440e3a2b-043c-4835-a59b-96deffb72f01:#{projectname}")
        return projectuuid if !projectuuid.nil?
        projectuuid = Items::items().select{|item| item["projectname"] == projectname }.first["projectuuid"]
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
        Items::items().select{|item| item["projectuuid"] == projectuuid }
    end

end
