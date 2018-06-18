
# encoding: UTF-8

require_relative "Bob.rb"

# Alphabetic order

# CommonsUtils::codeToDatetimeOrNull(code)
# CommonsUtils::currentHour()
# CommonsUtils::currentDay()
# CommonsUtils::isLucille18()
# CommonsUtils::isActiveInstance(runId)
# CommonsUtils::isInteger(str)
# CommonsUtils::isFloat(str)
# CommonsUtils::newBinArchivesFolderpath()
# CommonsUtils::realNumbersToZeroOne(x, origin, unit)
# CommonsUtils::simplifyURLCarryingString(string)
# CommonsUtils::screenHeight()
# CommonsUtils::screenWidth()
# CommonsUtils::traceToRealInUnitInterval(trace)
# CommonsUtils::traceToMetricShift(trace)
# CommonsUtils::waveInsertNewItemInteractive(description)
# CommonsUtils::getStructure2B7DC24F()
# CommonsUtils::getNthElementOfUnifiedListing(n)
# CommonsUtils::getLightSpeed()
# CommonsUtils::setLightSpeed(value)

class CommonsUtils

    def self.currentHour()
        Time.new.to_s[0,13]
    end

    def self.currentDay()
        Time.new.to_s[0,10]
    end

    def self.isInteger(str)
        str.to_i.to_s == str
    end

    def self.isFloat(str)
        str.to_f.to_s == str
    end

    def self.traceToRealInUnitInterval(trace)
        ( '0.'+Digest::SHA1.hexdigest(trace).gsub(/[^\d]/, '') ).to_f
    end

    def self.traceToMetricShift(trace)
        0.001*CommonsUtils::traceToRealInUnitInterval(trace)
    end

    def self.realNumbersToZeroOne(x, pointAtZeroDotFive, unit)
        alpha =
            if x >= pointAtZeroDotFive then
                2-Math.exp(-(x-pointAtZeroDotFive).to_f/unit)
            else
                Math.exp((x-pointAtZeroDotFive).to_f/unit)
            end
        alpha.to_f/2
    end

    def self.screenHeight()
        `/usr/bin/env tput lines`.to_i
    end

    def self.screenWidth()
        `/usr/bin/env tput cols`.to_i
    end

    def self.codeToDatetimeOrNull(code)
        localsuffix = Time.new.to_s[-5,5]
        if code[0,1]=='+' then
            code = code[1,999]
            if code.index('@') then
                # The first part is an integer and the second HH:MM
                part1 = code[0,code.index('@')]
                part2 = code[code.index('@')+1,999]
                "#{( DateTime.now + part1.to_i ).to_date.to_s} #{part2}:00 #{localsuffix}"
            else
                if code.include?('days') or code.include?('day') then
                    if code.include?('days') then
                        # The entire string is to be interpreted as a number of days from now
                        "#{( DateTime.now + code[0,code.size-4].to_f ).to_time.to_s}"
                    else
                        # The entire string is to be interpreted as a number of days from now
                        "#{( DateTime.now + code[0,code.size-3].to_f ).to_time.to_s}"
                    end

                elsif code.include?('hours') or code.include?('hour') then
                    if code.include?('hours') then
                        ( Time.new + code[0,code.size-5].to_f*3600 ).to_s
                    else
                        ( Time.new + code[0,code.size-4].to_f*3600 ).to_s
                    end
                else
                    nil
                end
            end
        else
            # Here we expect "YYYY-MM-DD" or "YYYY-MM-DD@HH:MM"
            if code.index('@') then
                part1 = code[0,10]
                part2 = code[11,999]
                "#{part1} #{part2}:00 #{localsuffix}"
            else
                part1 = code[0,10]
                part2 = code[11,999]
                "#{part1} 00:00:00 #{localsuffix}"
            end
        end
    end

    def self.editTextUsingTextmate(text)
      filename = SecureRandom.hex
      filepath = "/tmp/#{filename}"
      File.open(filepath, 'w') {|f| f.write(text)}
      system("/usr/local/bin/mate \"#{filepath}\"")
      print "> press enter when done: "
      input = STDIN.gets
      IO.read(filepath)
    end

    def self.isLucille18()
        ENV["COMPUTERLUCILLENAME"]==Config::get("PrimaryComputerName")
    end

    def self.isActiveInstance(runId)
        IO.read("#{CATALYST_COMMON_DATABANK_FOLDERPATH}/run-identifier.data")==runId
    end

    def self.getStandardListingPosition()
        FKVStore::getOrDefaultValue("301bc639-db20-4eff-bc84-94b4b9e4c133", "1").to_i
    end

    def self.setStandardListingPosition(position)
        FKVStore::set("301bc639-db20-4eff-bc84-94b4b9e4c133", position)
    end

    # -----------------------------------------

    def self.announceWithColor(announce, object)
        if object["metric"]>1 then
            if object["announce"].include?("[PAUSED]") then
                announce = announce.yellow
            else
                announce = announce.green                
            end
        end
        announce
    end

    def self.emailSync(verbose)
        begin
            GeneralEmailClient::sync(JSON.parse(IO.read("#{CATALYST_COMMON_DATABANK_FOLDERPATH}/Agents-Data/Wave/Wave-Email-Config/guardian-relay.json")), verbose)
            OperatorEmailClient::download(JSON.parse(IO.read("#{CATALYST_COMMON_DATABANK_FOLDERPATH}/Agents-Data/Wave/Wave-Email-Config/operator.json")), verbose)
        rescue
        end
    end

    def self.newBinArchivesFolderpath()
        time = Time.new
        targetFolder = "#{CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH}/#{time.strftime("%Y")}/#{time.strftime("%Y%m")}/#{time.strftime("%Y%m%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}"
        FileUtils.mkpath(targetFolder)
        targetFolder       
    end

    def self.object2DonotShowUntilAsString(object)
        ( object["do-not-show-until-datetime"] and Time.new.to_s < object["do-not-show-until-datetime"] ) ? " (do not show until: #{object["do-not-show-until-datetime"]})" : ""
    end

    def self.processItemDescriptionPossiblyAsTextEditorInvitation(description)
        if description=='text' then
            editTextUsingTextmate("")
        else
            description
        end
    end

    def self.simplifyURLCarryingString(string)
        return string if /http/.match(string).nil?
        [/^\{\s\d*\s\}/, /^\[\]/, /^line:/, /^todo:/, /^url:/, /^\[\s*\d*\s*\]/]
            .each{|regex|
                if ( m = regex.match(string) ) then
                    string = string[m.to_s.size, string.size].strip
                    return CommonsUtils::simplifyURLCarryingString(string)
                end
            }
        string
    end

    def self.selectRequirementFromExistingRequirementsOrNull()
        LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("requirement", RequirementsOperator::getAllRequirements())
    end

    def self.waveInsertNewItemDefaults(description) # uuid: String
        description = CommonsUtils::processItemDescriptionPossiblyAsTextEditorInvitation(description)
        uuid = SecureRandom.hex(4)
        folderpath = AgentWave::timestring22ToFolderpath(LucilleCore::timeStringL22())
        FileUtils.mkpath folderpath
        File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(uuid) }
        File.open("#{folderpath}/description.txt", 'w') {|f| f.write(description) }
        schedule = WaveSchedules::makeScheduleObjectTypeNew()
        schedule["made-on-date"] = CommonsUtils::currentDay()
        AgentWave::writeScheduleToDisk(uuid,schedule)
        uuid
    end

    def self.waveInsertNewItemInteractive(description)
        description = CommonsUtils::processItemDescriptionPossiblyAsTextEditorInvitation(description)
        uuid = SecureRandom.hex(4)
        folderpath = AgentWave::timestring22ToFolderpath(LucilleCore::timeStringL22())
        FileUtils.mkpath folderpath
        File.open("#{folderpath}/catalyst-uuid", 'w') {|f| f.write(uuid) }
        File.open("#{folderpath}/description.txt", 'w') {|f| f.write(description) }
        print "Default schedule is today, would you like to make another one ? [yes/no] (default: no): "
        answer = STDIN.gets().strip 
        schedule = 
            if answer=="yes" then
                WaveSchedules::makeScheduleObjectInteractivelyEnsureChoice()
            else
                x = WaveSchedules::makeScheduleObjectTypeNew()
                x["made-on-date"] = CommonsUtils::currentDay()
                x
            end
        AgentWave::writeScheduleToDisk(uuid,schedule)
        if (datetimecode = LucilleCore::askQuestionAnswerAsString("datetime code ? (empty for none) : ")).size>0 then
            if (datetime = CommonsUtils::codeToDatetimeOrNull(datetimecode)) then
                TheFlock::setDoNotShowUntilDateTime(uuid, datetime)
                EventsManager::commitEventToTimeline(EventsMaker::doNotShowUntilDateTime(uuid, datetime))
            end
        end
        print "Move to a project ? [yes/no] (default: no): "
        answer = STDIN.gets().strip 
        if answer=="yes" then
            ProjectsCore::addObjectUUIDToProjectInteractivelyChosen(uuid)
        end
    end

    # -----------------------------------------

    def self.fDoNotShowUntilDateTimeTransform()
        TheFlock::flockObjects().map{|object|
            if !TheFlock::getDoNotShowUntilDateTimeDistribution()[object["uuid"]].nil? and (Time.new.to_s < TheFlock::getDoNotShowUntilDateTimeDistribution()[object["uuid"]]) and object["metric"]<=1 then
                # The second condition in case we start running an object that wasn't scheduled to be shown today (they can be found through search)
                object["do-not-show-until-datetime"] = TheFlock::getDoNotShowUntilDateTimeDistribution()[object["uuid"]]
                object["metric"] = 0
                TheFlock::addOrUpdateObject(object)
            end
        }
    end

    def self.flockOrderedDisplayObjects()
        # The first upgrade should come first as it makes objects building, metric updates etc.
        # All the others send metric to zero when relevant and they are all commutative.
        RequirementsOperator::transform()
        CommonsUtils::fDoNotShowUntilDateTimeTransform()
        ProjectsCore::transform()
        Ordinals::transform()
        TheFlock::flockObjects()
            .select{|object| object["metric"] > 0 }
            .sort{|o1,o2| o1['metric']<=>o2['metric'] }
            .reverse
    end

    def self.getStructure2B7DC24F()
        Bob::generalFlockUpgrade()
        structure_2b7dc24f = []
        Ordinals::sortedDistribution()
            .select{|pair| TheFlock::getObjectByUUIDOrNull(pair[0]).nil? }
            .each{|pair| Ordinals::unregister(pair[0]) }
        pairs = Ordinals::sortedDistribution()
        pairs.each{|pair|
            structure_2b7dc24f << {
                "type" => "ordinal",
                "object" => TheFlock::getObjectByUUIDOrNull(pair[0]),
                "ordinal" => pair[1]
            }
        }
        CommonsUtils::flockOrderedDisplayObjects().each{|object|
            structure_2b7dc24f << {
                "type" => "main",
                "object" => object
            }
        }
        structure_2b7dc24f
    end

    def self.getNthElementOfUnifiedListing(n) # { :type, :object, :ordinal optional}
        CommonsUtils::getStructure2B7DC24F().take(n).last
    end

    # -----------------------------------------

    def self.putshelp()
        puts "Special General Commands"
        puts "    help"
        puts "    top"
        puts "    search <pattern: String>"
        puts "    r:on <requirement: String>"
        puts "    r:off <requirement: String>"
        puts "    r:show [requirement] # optional parameter # shows all the objects of that requirement"
        puts "    projects # projects dive"
        puts "    email-sync  # run email sync"
        puts "    interface   # select an agent and run the interface"
        puts "    lib         # Invoques the Librarian interactive"
        puts "    toggle"
        puts ""
        puts "Special General Commands (inserts)"
        puts "    wave: <description: String>>"
        puts "    stream: <description: String>"
        puts "    project: <description: String>"
        puts "    time commitment: [guardian:] <description>"
        puts ""
        puts "Special Commands (object targetting and ordinal)"
        puts "    :<position>           # set the listing reference point"
        puts "    :<position> open      # send command open to the item at position"
        puts "    :<position> done      # send command done to the item at position"
        puts "    :<position> <float>   # set the ordinal of the object at this position"
        puts "    :this <float>         # register the current object agains the float"
        puts "    :this goto:project # send the current object to a project"
        puts "    :? <float> <description, multi-tokens> # creates a text object and give it that ordinal"
        puts ""
        puts "Special Object Commands:"
        puts "    + # push by 1 hour"
        puts "    +datetimecode"
        puts "    expose # pretty print the object"
        puts "    r:add <requirement: String>"
        puts "    r:remove <requirement: String>"
        puts "    :<position: Integer> # select and operate on the object number <integer>"
        puts "    command ..."
    end

    def self.object2Line_v0(object)
        announce = object['announce'].lines.first.strip
        announce = CommonsUtils::announceWithColor(announce, object)
        [
            "(#{"%.3f" % object["metric"]})",
            " [#{object["uuid"]}]",
            " #{announce}",
            CommonsUtils::object2DonotShowUntilAsString(object),
        ].join()
    end

    def self.processObjectAndCommand(object, expression)

        # no object needed

        if expression == 'help' then
            CommonsUtils::putshelp()
            LucilleCore::pressEnterToContinue()
            return
        end

        if expression == "interface" then
            LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("agent", Bob::agents(), lambda{ |agent| agent["agent-name"] })["interface"].call()
            return
        end

        if expression == 'info' then
            puts "CatalystDevOps::getArchiveTimelineSizeInMegaBytes(): #{CatalystDevOps::getArchiveTimelineSizeInMegaBytes()}".green
            puts "Todolists:".green
            puts "    Stream count : #{( count1 = AgentStream::getUUIDs().size )}".green
            puts "    Vienna count : #{(count3 = $viennaLinkFeeder.links().count)}".green
            puts "    Total        : #{(count1+count3)}".green
            puts "Requirements:".green
            puts "    On  : #{(RequirementsOperator::getAllRequirements() - RequirementsOperator::getCurrentlyUnsatisfiedRequirements()).join(", ")}".green
            puts "    Off : #{RequirementsOperator::getCurrentlyUnsatisfiedRequirements().join(", ")}".green
            LucilleCore::pressEnterToContinue()
            return
        end

        if expression == 'lib' then
            LibrarianExportedFunctions::librarianUserInterface_librarianInteractive()
            return
        end

        if expression == 'email-sync' then
            CommonsUtils::emailSync(true)
            return
        end

        if expression == "projects" then
            ProjectsCore::ui_projectsDive()
            return
        end

        if expression.start_with?('wave:') then
            description = expression[5, expression.size].strip
            CommonsUtils::waveInsertNewItemInteractive(description)
            #LucilleCore::pressEnterToContinue()
            return
        end

        if expression.start_with?('stream:') then
            description = expression[7, expression.size].strip
            description = CommonsUtils::processItemDescriptionPossiblyAsTextEditorInvitation(description)
            folderpath = AgentStream::issueNewItemWithDescription(description)
            puts "created item: #{folderpath}"
            LucilleCore::pressEnterToContinue()
            return
        end

        if expression.start_with?('project:') then
            description = expression[8, expression.size].strip
            description = CommonsUtils::processItemDescriptionPossiblyAsTextEditorInvitation(description)
            projectuuid = ProjectsCore::createNewProject(description)
            puts "project uuid: #{projectuuid}"
            puts "project name: #{description}"
            LucilleCore::pressEnterToContinue()
            return
        end

        if expression.start_with?('time commitment:') then
            command = expression[16, expression.size].strip
            timeInHours, description = StringParser::decompose(command)
            description = description ? description : ""
            timepoint = TimePointsCore::issueNewPoint(
                SecureRandom.hex(8), 
                description, 
                timeInHours.to_f, 
                description.start_with?("guardian:"))
            timepoint["metric"] = 0.8
            TimePointsCore::saveTimePoint(timepoint)
            puts JSON.pretty_generate(timepoint)
            LucilleCore::pressEnterToContinue()
            return
        end        

        if expression.start_with?("r:on") then
            command, requirement = expression.split(" ").map{|t| t.strip }
            RequirementsOperator::setSatisfifiedRequirement(requirement)
            return
        end

        if expression.start_with?("r:off") then
            command, requirement = expression.split(" ").map{|t| t.strip }
            RequirementsOperator::setUnsatisfiedRequirement(requirement)
            return
        end

        if expression.start_with?("r:show") then
            command, requirement = expression.split(" ").map{|t| t.strip }
            if requirement.nil? or requirement.size==0 then
                requirement = CommonsUtils::selectRequirementFromExistingRequirementsOrNull()
            end
            loop {
                requirementObjects = TheFlock::flockObjects().select{ |object| RequirementsOperator::getObjectRequirements(object['uuid']).include?(requirement) }
                selectedobject = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("object", requirementObjects, lambda{ |object| CommonsUtils::object2Line_v0(object) })
                break if selectedobject.nil?
                CommonsUtils::doPresentObjectInviteAndExecuteCommand(selectedobject)
            }
            return
        end

        if expression.start_with?("search") then
            pattern = expression[6,expression.size].strip
            loop {
                FlockDiskIO::loadFromEventsTimeline()
                Bob::generalFlockUpgrade()
                searchobjects = TheFlock::flockObjects().select{|object| CommonsUtils::object2Line_v0(object).downcase.include?(pattern.downcase) }
                break if searchobjects.size==0
                selectedobject = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("object", searchobjects, lambda{ |object| CommonsUtils::object2Line_v0(object) })
                break if selectedobject.nil?
                CommonsUtils::doPresentObjectInviteAndExecuteCommand(selectedobject)
            }
            return
        end

        return if object.nil?

        # object needed

        if expression == 'expose' then
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return
        end

        if expression.start_with?('+') then
            code = expression
            if (datetime = CommonsUtils::codeToDatetimeOrNull(code)) then
                TheFlock::setDoNotShowUntilDateTime(object["uuid"], datetime)
                EventsManager::commitEventToTimeline(EventsMaker::doNotShowUntilDateTime(object["uuid"], datetime))
                Ordinals::unregister(object["uuid"])
            end
            return
        end

        if expression.start_with?("r:add") then
            command, requirement = expression.split(" ").map{|t| t.strip }
            RequirementsOperator::addRequirementToObject(object['uuid'],requirement)
            return
        end

        if expression.start_with?("r:remove") then
            command, requirement = expression.split(" ").map{|t| t.strip }
            RequirementsOperator::removeRequirementFromObject(object['uuid'],requirement)
            return
        end

        if expression.size > 0 then
            tokens = expression.split(" ").map{|t| t.strip }
            .each{|command|
                Bob::agentuuid2AgentData(object["agent-uid"])["object-command-processor"].call(object, command)
            }
        else
            Bob::agentuuid2AgentData(object["agent-uid"])["object-command-processor"].call(object, "")
        end
    end

    def self.doPresentObjectInviteAndExecuteCommand(object)
        return if object.nil?
        puts CatalystInterfaceUtils::object2Line_v1(object)
        print "--> "
        command = STDIN.gets().strip
        command = command.size>0 ? command : ( object["default-expression"] ? object["default-expression"] : "" )
        CommonsUtils::processObjectAndCommand(object, command)
    end

    def self.getLightSpeed()
        FKVStore::getOrDefaultValue("SPEED-OF-LIGHT-BCAA047D-C277-41DB-9887-7EB5E468255F", "1").to_f
    end

    def self.setLightSpeed(value)
        FKVStore::set("SPEED-OF-LIGHT-BCAA047D-C277-41DB-9887-7EB5E468255F", value)
    end
end
