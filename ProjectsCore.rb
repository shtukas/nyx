
# encoding: UTF-8


# -------------------------------------------------------------

# Collections was born out of what was originally known as Threads and Projects

# -------------------------------------------------------------

# ---------------------------------------------------
# Utils

# ProjectsCore::projectsFolderpaths()
# ProjectsCore::folderPath2ProjectUUIDOrNull(folderpath)
# ProjectsCore::folderPath2CollectionName(folderpath)
# ProjectsCore::folderPath2CollectionObject(folderpath)
# ProjectsCore::projectUUID2FolderpathOrNull(uuid)
# ProjectsCore::projectsUUIDs()
# ProjectsCore::projectsNames()
# ProjectsCore::projectUUID2NameOrNull(projectuuid)
# ProjectsCore::projectsPositionalCoefficientSequence()

# ---------------------------------------------------
# text and documents

# ProjectsCore::textContents(projectuuid)
# ProjectsCore::documentsFilenames(projectuuid)

# ---------------------------------------------------
# creation

# ProjectsCore::createNewProject(projectname)

# ---------------------------------------------------
# projects uuids

# ProjectsCore::addCatalystObjectUUIDToProject(objectuuid, projectuuid)
# ProjectsCore::addObjectUUIDToProjectInteractivelyChosen(objectuuid, projectuuid)
# ProjectsCore::projectCatalystObjectUUIDs(projectuuid)
# ProjectsCore::projectCatalystObjectUUIDsThatAreAlive(projectuuid)
# ProjectsCore::allProjectsCatalystUUIDs()

# ---------------------------------------------------
# isGuardianTime?(projectuuid)

# ProjectsCore::isGuardianTime?(projectuuid)
# ProjectsCore::setTimePointGenerator(projectuuid, periodInSeconds, timepointDurationInSeconds)
# ProjectsCore::getTimePointGeneratorOrNull(projectuuid): [ <operationUnixtime> <periodInSeconds> <timepointDurationInSeconds> ]
# ProjectsCore::resetTimePointGenerator(projectuuid)

# ---------------------------------------------------
# Misc

# ProjectsCore::transform()
# ProjectsCore::sendProjectToBinTimeline(uuid)
# ProjectsCore::getProjectTimeCoefficient(uuid)
# ProjectsCore::agentDailyCommitmentInHours()
# ProjectsCore::getProjectTimeCoefficient(uuid)

# ---------------------------------------------------
# User Interface

# ProjectsCore::interactivelySelectProjectUUIDOrNUll()
# ProjectsCore::ui_ProjectsDive()
# ProjectsCore::ui_ProjectDive(projectuuid)
# ProjectsCore::completeProject(projectuuid)


class ProjectsCore

    # ---------------------------------------------------
    # Utils

    def self.projectsFolderpaths()
        Dir.entries(CATALYST_COMMON_PROJECTS_REPOSITORY_FOLDERPATH)
            .select{|filename| filename[0,1]!="." }
            .sort
            .map{|filename| "#{CATALYST_COMMON_PROJECTS_REPOSITORY_FOLDERPATH}/#{filename}" }
    end

    def self.projectsUUIDs()
        ProjectsCore::projectsFolderpaths().map{|folderpath| ProjectsCore::folderPath2ProjectUUIDOrNull(folderpath) }
    end

    def self.projectsNames()
        ProjectsCore::projectsFolderpaths().map{|folderpath| ProjectsCore::folderPath2CollectionName(folderpath) }
    end

    def self.folderPath2ProjectUUIDOrNull(folderpath)
        IO.read("#{folderpath}/collection-uuid")
    end

    def self.folderPath2CollectionName(folderpath)
        IO.read("#{folderpath}/collection-name")
    end

    def self.projectUUID2FolderpathOrNull(uuid)
        ProjectsCore::projectsFolderpaths()
            .each{|folderpath|
                return folderpath if ProjectsCore::folderPath2ProjectUUIDOrNull(folderpath)==uuid
            }
        nil
    end

    def self.projectUUID2NameOrNull(uuid)
        ProjectsCore::projectsFolderpaths()
            .each{|folderpath|
                return IO.read("#{folderpath}/collection-name").strip if ProjectsCore::folderPath2ProjectUUIDOrNull(folderpath)==uuid
            }
        nil
    end

    def self.projectsPositionalCoefficientSequence()
        LucilleCore::integerEnumerator().lazy.map{|n| 1.to_f/(2 ** n) }
    end

    # ---------------------------------------------------
    # text and documents

    def self.textContents(projectuuid)
        folderpath = projectUUID2FolderpathOrNull(projectuuid)
        return "" if folderpath.nil?
        IO.read("#{folderpath}/collection-text.txt")
    end    

    def self.documentsFilenames(projectuuid)
        folderpath = projectUUID2FolderpathOrNull(projectuuid)
        return [] if folderpath.nil?
        Dir.entries("#{folderpath}/documents").select{|filename| filename[0,1]!="." }
    end

    # ---------------------------------------------------
    # creation

    def self.createNewProject(projectname)
        projectuuid = SecureRandom.hex(4)
        foldername = LucilleCore::timeStringL22()
        folderpath = "#{CATALYST_COMMON_PROJECTS_REPOSITORY_FOLDERPATH}/#{foldername}"
        FileUtils.mkpath folderpath
        File.open("#{folderpath}/collection-uuid", "w"){|f| f.write(projectuuid) }
        File.open("#{folderpath}/collection-name", "w"){|f| f.write(projectname) }
        File.open("#{folderpath}/collection-catalyst-uuids.json", "w"){|f| f.puts(JSON.generate([])) }
        FileUtils.touch("#{folderpath}/collection-text.txt")
        FileUtils.mkpath "#{folderpath}/documents"
        projectuuid
    end

    # ---------------------------------------------------
    # projects uuids

    def self.addCatalystObjectUUIDToProject(objectuuid, projectuuid)
        folderpath = ProjectsCore::projectUUID2FolderpathOrNull(projectuuid)
        arrayFilepath = "#{folderpath}/collection-catalyst-uuids.json"
        array = JSON.parse(IO.read(arrayFilepath))
        array << objectuuid 
        array = array.uniq
        File.open(arrayFilepath, "w"){|f| f.puts(JSON.generate(array)) }
    end

    def self.addObjectUUIDToProjectInteractivelyChosen(objectuuid)
        projectuuid = ProjectsCore::interactivelySelectProjectUUIDOrNUll()
        if projectuuid.nil? then
            if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Would you like to create a new project ? ") then
                projectname = LucilleCore::askQuestionAnswerAsString("project name: ")
                projectuuid = ProjectsCore::createNewProject(projectname)
            else
                return
            end
        end
        ProjectsCore::addCatalystObjectUUIDToProject(objectuuid, projectuuid)
        projectuuid
    end

    def self.projectCatalystObjectUUIDs(projectuuid)
        folderpath = ProjectsCore::projectUUID2FolderpathOrNull(projectuuid)
        JSON.parse(IO.read("#{folderpath}/collection-catalyst-uuids.json"))
    end

    def self.projectCatalystObjectUUIDsThatAreAlive(projectuuid)
        a1 = ProjectsCore::projectCatalystObjectUUIDs(projectuuid)
        a2 = TheFlock::flockObjects().map{|object| object["uuid"] }
        a1 & a2
    end

    def self.allProjectsCatalystUUIDs()
        ProjectsCore::projectsFolderpaths()
            .map{|folderpath| JSON.parse(IO.read("#{folderpath}/collection-catalyst-uuids.json")) }
            .flatten
    end

    # ---------------------------------------------------
    # Time management & isGuardianTime?(projectuuid)

    def self.isGuardianTime?(projectuuid)
        folderpath = ProjectsCore::projectUUID2FolderpathOrNull(projectuuid)
        filepath = "#{folderpath}/isGuardianTime?"
        if !File.exists?(filepath) then
            if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("#{ProjectsCore::projectUUID2NameOrNull(projectuuid)} is Guardian time? ") then
                File.open(filepath, "w"){|f| f.write("true") }
            else
                File.open(filepath, "w"){|f| f.write("false") }
            end
        end
        IO.read(filepath).strip == "true" 
    end

    def self.setTimePointGenerator(projectuuid, periodInSeconds, timepointDurationInSeconds)
        folderpath = ProjectsCore::projectUUID2FolderpathOrNull(projectuuid)
        return if folderpath.nil?
        File.open("#{folderpath}/time-point-generator-8a3030a0", "w"){|f| f.write( JSON.generate([Time.new.to_i, periodInSeconds, timepointDurationInSeconds]) ) }        
    end
    def self.getTimePointGeneratorOrNull(projectuuid)
        folderpath = ProjectsCore::projectUUID2FolderpathOrNull(projectuuid)
        return nil if folderpath.nil?
        filepath = "#{folderpath}/time-point-generator-8a3030a0"
        return nil if !File.exists?(filepath)  
        JSON.parse(IO.read(filepath))    
    end
    def self.resetTimePointGenerator(projectuuid)
        # This function is called by AgentTimeGenesis when a new time point is issued
        generator = getTimePointGeneratorOrNull(projectuuid)
        return if generator.nil?
        self.setTimePointGenerator(projectuuid, generator[1], generator[2])
    end

    # ---------------------------------------------------
    # Misc

    def self.transform()
        uuids = self.allProjectsCatalystUUIDs()
        TheFlock::flockObjects().each{|object|
            if uuids.include?(object["uuid"]) then
                object["metric"] = 0
                TheFlock::addOrUpdateObject(object)
            end
        }
    end

    def self.sendProjectToBinTimeline(uuid)
        sourcefilepath = ProjectsCore::projectUUID2FolderpathOrNull(uuid)
        return if sourcefilepath.nil?
        targetFolder = CommonsUtils::newBinArchivesFolderpath()
        puts "source: #{sourcefilepath}"
        puts "target: #{targetFolder}"
        LucilleCore::copyFileSystemLocation(sourcefilepath, targetFolder)
        LucilleCore::removeFileSystemLocation(sourcefilepath)
    end

    def self.getNextReviewUnixtime(projectuuid)
        folderpath = ProjectsCore::projectUUID2FolderpathOrNull(projectuuid)
        filepath = "#{folderpath}/collection-next-review-time"
        return 0 if !File.exists?(filepath)
        IO.read(filepath).to_i       
    end

    def self.setNextReviewUnixtime(projectuuid)
        folderpath = ProjectsCore::projectUUID2FolderpathOrNull(projectuuid)
        filepath = "#{folderpath}/collection-next-review-time"
        unixtime = Time.new.to_i + 86400*(1+rand) 
        File.open(filepath, "w"){|f| f.write(unixtime) }
    end

    # ---------------------------------------------------
    # User Interface

    def self.ui_destroyProject(projectuuid)
        if ProjectsCore::textContents(projectuuid).strip.size>0 then
            puts "You now need to review the file"
            system("open '#{projectUUID2FolderpathOrNull(projectuuid)}'")
            LucilleCore::pressEnterToContinue()
        end
        if ProjectsCore::documentsFilenames(projectuuid).size>0 then
            puts "You now need to recview the documents"
            system("open '#{projectUUID2FolderpathOrNull(projectuuid)}/documents'")
            LucilleCore::pressEnterToContinue()
        end
        if ProjectsCore::projectCatalystObjectUUIDs(projectuuid).size>0 then
            puts "You now need to destroy all the objects"
            LucilleCore::pressEnterToContinue()
            loop {
                break if ProjectsCore::projectCatalystObjectUUIDs(projectuuid).size==0
                ProjectsCore::projectCatalystObjectUUIDs(projectuuid)
                    .map{|objectuuid| TheFlock::getObjectByUUIDOrNull(objectuuid) }
                    .compact
                    .each{|object|
                        CommonsUtils::doPresentObjectInviteAndExecuteCommand(object)
                    }
            }
        end
        puts "Moving project folder to bin timeline"
        projectfolderpath = ProjectsCore::projectUUID2FolderpathOrNull(projectuuid)
        targetFolder = CommonsUtils::newBinArchivesFolderpath()
        FileUtils.mv(projectfolderpath, targetFolder)        
    end

    def self.ui_ProjectDive(projectuuid)
        loop {
            textContents = ProjectsCore::textContents(projectuuid)
            documentsFilenames = ProjectsCore::documentsFilenames(projectuuid)
            catalystobjects = ProjectsCore::projectCatalystObjectUUIDs(projectuuid)
                .map{|objectuuid| TheFlock::flockObjectsAsMap()[objectuuid] }
                .compact
                .sort{|o1,o2| o1['metric']<=>o2['metric'] }
                .reverse
            menuItem1 = "file      : (#{textContents.strip.size} characters)"
            menuItem2 = "documents : (#{documentsFilenames.size} files)"
            menuItem5 = "operation : destroy"            
            menuStringsOrCatalystObjects = catalystobjects + [menuItem1, menuItem2 ]
            menuStringsOrCatalystObjects = menuStringsOrCatalystObjects + [ menuItem8, menuItem5 ]
            toStringLambda = lambda{ |menuStringOrCatalystObject|
                # Here item is either one of the strings or an object
                # We return either a string or one of the objects
                if menuStringOrCatalystObject.class.to_s == "String" then
                    string = menuStringOrCatalystObject
                    string
                else
                    object = menuStringOrCatalystObject
                    "object    : #{CommonsUtils::object2Line_v0(object)}"
                end
            }
            menuChoice = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("menu", menuStringsOrCatalystObjects, toStringLambda)
            break if menuChoice.nil?
            if menuChoice == menuItem1 then
                folderpath = ProjectsCore::projectUUID2FolderpathOrNull(projectuuid)
                system("open '#{folderpath}/collection-text.txt'")
                next
            end
            if menuChoice == menuItem2 then
                folderpath = ProjectsCore::projectUUID2FolderpathOrNull(projectuuid)
                system("open '#{folderpath}/documents'")
                next
            end
            if menuChoice == menuItem5 then
                if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Are you sure you want to destroy this project ? ") and LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Seriously ? ") then
                    ProjectsCore::ui_destroyProject(projectuuid)
                end
                return
            end
            # By now, menuChoice is a catalyst object
            object = menuChoice
            CommonsUtils::doPresentObjectInviteAndExecuteCommand(object)
        }
    end

    def self.completeProject(projectuuid)
        folderpath = ProjectsCore::projectUUID2FolderpathOrNull(uuid)
        return if folderpath.nil?
        if self.hasText(folderpath) then
            puts "You cannot complete this item because it has text"
            LucilleCore::pressEnterToContinue()
            return
        end
        if self.hasDocuments(folderpath) then
            puts "You cannot complete this item because it has documents"
            LucilleCore::pressEnterToContinue()
            return
        end
        if ProjectsCore::projectCatalystObjectUUIDsThatAreAlive(projectuuid).size>0 then
            puts "You cannot complete this item because it has objects"
            LucilleCore::pressEnterToContinue()
            return
        end
        Chronos::stop(projectuuid)
        ProjectsCore::sendProjectToBinTimeline(projectuuid)
    end

    def self.ui_ProjectsDive()
        loop {
            toString = lambda{ |projectuuid| 
                "#{ProjectsCore::getCollectionStyle(projectuuid).ljust(8)} : #{ProjectsCore::projectUUID2NameOrNull(projectuuid)}"
            }
            projectuuid = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("projects", ProjectsCore::projectsUUIDs(), toString)
            break if projectuuid.nil?
            ProjectsCore::ui_ProjectDive(projectuuid)
        }
    end

    def self.interactivelySelectProjectUUIDOrNUll()
        LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("project", ProjectsCore::projectsUUIDs(), lambda{ |projectuuid| ProjectsCore::projectUUID2NameOrNull(projectuuid) })
    end

end