
# encoding: UTF-8


# -------------------------------------------------------------

# Collections was born out of what was originally known as Threads and Projects

# -------------------------------------------------------------

# CollectionsCore::collectionsFolderpaths()
# CollectionsCore::folderPath2CollectionUUIDOrNull(folderpath)
# CollectionsCore::folderPath2CollectionName(folderpath)
# CollectionsCore::folderPath2CollectionObject(folderpath)
# CollectionsCore::collectionUUID2FolderpathOrNull(uuid)
# CollectionsCore::collectionsUUIDs()
# CollectionsCore::collectionsNames()
# CollectionsCore::collectionUUID2NameOrNull(collectionuuid)

# CollectionsCore::textContents(collectionuuid)
# CollectionsCore::documentsFilenames(collectionuuid)

# CollectionsCore::createNewCollection_WithNameAndStyle(collectionname, style)

# CollectionsCore::addCatalystObjectUUIDToCollection(objectuuid, threaduuid)
# CollectionsCore::addObjectUUIDToCollectionInteractivelyChosen(objectuuid, threaduuid)
# CollectionsCore::collectionCatalystObjectUUIDs(threaduuid)
# CollectionsCore::collectionCatalystObjectUUIDsThatAreAlive(collectionuuid)
# CollectionsCore::allCollectionsCatalystUUIDs()

# CollectionsCore::setCollectionStyle(collectionuuid, style)
# CollectionsCore::getCollectionStyle(collectionuuid)

# CollectionsCore::isGuardianTime?(collectionuuid)

# CollectionsCore::transform()
# CollectionsCore::sendCollectionToBinTimeline(uuid)
# CollectionsCore::getCollectionTimeCoefficient(uuid)
# CollectionsCore::agentDailyCommitmentInHours()
# CollectionsCore::getCollectionTimeCoefficient(uuid)

# CollectionsCore::interactivelySelectCollectionUUIDOrNUll()
# CollectionsCore::ui_CollectionsDive()
# CollectionsCore::ui_CollectionDive(collectionuuid)

# CollectionsCore::startCollection(collectionuuid)
# CollectionsCore::stopCollection(collectionuuid)
# CollectionsCore::completeCollection(collectionuuid)

class CollectionsCore

    # ---------------------------------------------------
    # Utils

    def self.collectionsFolderpaths()
        Dir.entries(CATALYST_COMMON_COLLECTIONS_REPOSITORY_FOLDERPATH)
            .select{|filename| filename[0,1]!="." }
            .sort
            .map{|filename| "#{CATALYST_COMMON_COLLECTIONS_REPOSITORY_FOLDERPATH}/#{filename}" }
    end

    def self.collectionsUUIDs()
        CollectionsCore::collectionsFolderpaths().map{|folderpath| CollectionsCore::folderPath2CollectionUUIDOrNull(folderpath) }
    end

    def self.collectionsNames()
        CollectionsCore::collectionsFolderpaths().map{|folderpath| CollectionsCore::folderPath2CollectionName(folderpath) }
    end

    def self.folderPath2CollectionUUIDOrNull(folderpath)
        IO.read("#{folderpath}/collection-uuid")
    end

    def self.folderPath2CollectionName(folderpath)
        IO.read("#{folderpath}/collection-name")
    end

    def self.collectionUUID2FolderpathOrNull(uuid)
        CollectionsCore::collectionsFolderpaths()
            .each{|folderpath|
                return folderpath if CollectionsCore::folderPath2CollectionUUIDOrNull(folderpath)==uuid
            }
        nil
    end

    def self.collectionUUID2NameOrNull(uuid)
        CollectionsCore::collectionsFolderpaths()
            .each{|folderpath|
                return IO.read("#{folderpath}/collection-name").strip if CollectionsCore::folderPath2CollectionUUIDOrNull(folderpath)==uuid
            }
        nil
    end

    # ---------------------------------------------------
    # text and documents

    def self.textContents(collectionuuid)
        folderpath = collectionUUID2FolderpathOrNull(collectionuuid)
        return "" if folderpath.nil?
        IO.read("#{folderpath}/collection-text.txt")
    end    

    def self.documentsFilenames(collectionuuid)
        folderpath = collectionUUID2FolderpathOrNull(collectionuuid)
        return [] if folderpath.nil?
        Dir.entries("#{folderpath}/documents").select{|filename| filename[0,1]!="." }
    end

    # ---------------------------------------------------
    # creation

    def self.createNewCollection_WithNameAndStyle(collectionname, style)
        collectionuuid = SecureRandom.hex(4)
        foldername = LucilleCore::timeStringL22()
        folderpath = "#{CATALYST_COMMON_COLLECTIONS_REPOSITORY_FOLDERPATH}/#{foldername}"
        FileUtils.mkpath folderpath
        File.open("#{folderpath}/collection-uuid", "w"){|f| f.write(collectionuuid) }
        File.open("#{folderpath}/collection-name", "w"){|f| f.write(collectionname) }
        File.open("#{folderpath}/collection-catalyst-uuids.json", "w"){|f| f.puts(JSON.generate([])) }
        FileUtils.touch("#{folderpath}/collection-text.txt")
        FileUtils.mkpath "#{folderpath}/documents"
        self.setCollectionStyle(collectionuuid, style)
        collectionuuid
    end

    # ---------------------------------------------------
    # collections uuids

    def self.addCatalystObjectUUIDToCollection(objectuuid, threaduuid)
        folderpath = CollectionsCore::collectionUUID2FolderpathOrNull(threaduuid)
        arrayFilepath = "#{folderpath}/collection-catalyst-uuids.json"
        array = JSON.parse(IO.read(arrayFilepath))
        array << objectuuid 
        array = array.uniq
        File.open(arrayFilepath, "w"){|f| f.puts(JSON.generate(array)) }
    end

    def self.addObjectUUIDToCollectionInteractivelyChosen(objectuuid)
        collectionuuid = CollectionsCore::interactivelySelectCollectionUUIDOrNUll()
        if collectionuuid.nil? then
            if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Would you like to create a new collection ? ") then
                collectionname = LucilleCore::askQuestionAnswerAsString("collection name: ")
                style = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("style", ["THREAD", "PROJECT"])
                collectionuuid = CollectionsCore::createNewCollection_WithNameAndStyle(collectionname, style)
            else
                return
            end
        end
        CollectionsCore::addCatalystObjectUUIDToCollection(objectuuid, collectionuuid)
        collectionuuid
    end

    def self.collectionCatalystObjectUUIDs(collectionuuid)
        folderpath = CollectionsCore::collectionUUID2FolderpathOrNull(collectionuuid)
        JSON.parse(IO.read("#{folderpath}/collection-catalyst-uuids.json"))
    end

    def self.collectionCatalystObjectUUIDsThatAreAlive(collectionuuid)
        a1 = CollectionsCore::collectionCatalystObjectUUIDs(collectionuuid)
        a2 = FlockOperator::flockObjects().map{|object| object["uuid"] }
        a1 & a2
    end

    def self.allCollectionsCatalystUUIDs()
        CollectionsCore::collectionsFolderpaths()
            .map{|folderpath| JSON.parse(IO.read("#{folderpath}/collection-catalyst-uuids.json")) }
            .flatten
    end

    # ---------------------------------------------------
    # style

    def self.setCollectionStyle(collectionuuid, style)
        if !["THREAD", "PROJECT"].include?(style) then
            raise "Incorrect Style: #{style}, should be THREAD or PROJECT"
        end
        folderpath = CollectionsCore::collectionUUID2FolderpathOrNull(collectionuuid)
        filepath = "#{folderpath}/collection-style"
        File.open(filepath, "w"){|f| f.write(style) }
    end

    def self.getCollectionStyle(collectionuuid)
        folderpath = CollectionsCore::collectionUUID2FolderpathOrNull(collectionuuid)
        filepath = "#{folderpath}/collection-style"
        IO.read(filepath).strip        
    end

    # ---------------------------------------------------
    # isGuardianTime?(collectionuuid)

    def self.isGuardianTime?(collectionuuid)
        folderpath = CollectionsCore::collectionUUID2FolderpathOrNull(collectionuuid)
        filepath = "#{folderpath}/isGuardianTime?"
        if !File.exists?(filepath) then
            if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("#{CollectionsCore::collectionUUID2NameOrNull(collectionuuid)} is Guardian time? ") then
                File.open(filepath, "w"){|f| f.write("true") }
            else
                File.open(filepath, "w"){|f| f.write("false") }
            end
        end
        IO.read(filepath).strip == "true" 
    end

    # ---------------------------------------------------
    # Misc

    def self.transform()
        uuids = self.allCollectionsCatalystUUIDs()
        FlockOperator::flockObjects().each{|object|
            if uuids.include?(object["uuid"]) then
                object["metric"] = 0
                FlockOperator::addOrUpdateObject(object)
            end
        }
    end

    def self.sendCollectionToBinTimeline(uuid)
        sourcefilepath = CollectionsCore::collectionUUID2FolderpathOrNull(uuid)
        return if sourcefilepath.nil?
        targetFolder = CommonsUtils::newBinArchivesFolderpath()
        puts "source: #{sourcefilepath}"
        puts "target: #{targetFolder}"
        LucilleCore::copyFileSystemLocation(sourcefilepath, targetFolder)
        LucilleCore::removeFileSystemLocation(sourcefilepath)
    end

    def self.getCollectionTimeCoefficient(uuid)
        folderpath = CollectionsCore::collectionUUID2FolderpathOrNull(uuid)
        if folderpath.nil? then
            raise "error e95e2fda: Could not find fodler path for uuid: #{uuid}" 
        end
        if File.exists?("#{folderpath}/collection-time-positional-coefficient") then
            return IO.read("#{folderpath}/collection-time-positional-coefficient").to_f
        end
        0
    end

    def self.getNextReviewUnixtime(collectionuuid)
        folderpath = CollectionsCore::collectionUUID2FolderpathOrNull(collectionuuid)
        filepath = "#{folderpath}/collection-next-review-time"
        return 0 if !File.exists?(filepath)
        IO.read(filepath).to_i       
    end

    def self.setNextReviewUnixtime(collectionuuid)
        folderpath = CollectionsCore::collectionUUID2FolderpathOrNull(collectionuuid)
        filepath = "#{folderpath}/collection-next-review-time"
        unixtime = Time.new.to_i + 86400*(1+rand) 
        File.open(filepath, "w"){|f| f.write(unixtime) }
    end

    # ---------------------------------------------------
    # User Interface

    def self.ui_CollectionDive(collectionuuid)
        loop {
            style = CollectionsCore::getCollectionStyle(collectionuuid)
            textContents = CollectionsCore::textContents(collectionuuid)
            documentsFilenames = CollectionsCore::documentsFilenames(collectionuuid)
            catalystobjects = CollectionsCore::collectionCatalystObjectUUIDs(collectionuuid)
                .map{|objectuuid| FlockOperator::flockObjectsAsMap()[objectuuid] }
                .compact
                .sort{|o1,o2| o1['metric']<=>o2['metric'] }
                .reverse
            menuItem1 = "file      : (#{textContents.strip.size} characters)"
            menuItem2 = "documents : (#{documentsFilenames.size} files)"
            menuItem6 = "operation : start"
            menuItem7 = "operation : stop"
            menuItem3 = "operation : recast as thread"
            menuItem4 = "operation : recast as project"
            menuItem5 = "operation : destroy"
            menuItem8 = "operation : add hours manually"            
            menuStringsOrCatalystObjects = catalystobjects + [menuItem1, menuItem2 ]
            if style == "PROJECT" then
                menuStringsOrCatalystObjects = menuStringsOrCatalystObjects + [ menuItem3 ]
            end
            if style == "THREAD" then
                menuStringsOrCatalystObjects = menuStringsOrCatalystObjects + [ menuItem4 ]
            end
            if GenericTimeTracking::status(collectionuuid)[0] then
                menuStringsOrCatalystObjects = menuStringsOrCatalystObjects + [ menuItem7 ]
            else
                menuStringsOrCatalystObjects = menuStringsOrCatalystObjects + [ menuItem6 ]
            end
            menuStringsOrCatalystObjects = menuStringsOrCatalystObjects + [ menuItem8 ]
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
                folderpath = CollectionsCore::collectionUUID2FolderpathOrNull(collectionuuid)
                system("open '#{folderpath}/collection-text.txt'")
                next
            end
            if menuChoice == menuItem2 then
                folderpath = CollectionsCore::collectionUUID2FolderpathOrNull(collectionuuid)
                system("open '#{folderpath}/documents'")
                next
            end
            if menuChoice == menuItem5 then
                if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Are you sure you want to destroy this #{style.downcase} ? ") and LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Seriously ? ") then
                    if catalystobjects.size>0 then
                        puts "You now need to destroy all the objects"
                        LucilleCore::pressEnterToContinue()
                        loop {
                            catalystobjects = CollectionsCore::collectionCatalystObjectUUIDs(collectionuuid)
                                .map{|objectuuid| FlockOperator::flockObjectsAsMap()[objectuuid] }
                                .compact
                                .sort{|o1,o2| o1['metric']<=>o2['metric'] }
                                .reverse
                            break if catalystobjects.size==0
                            object = catalystobjects.first
                            CommonsUtils::doPresentObjectInviteAndExecuteCommand(object)
                        }
                    end
                    puts "Moving collection folder to bin timeline"
                    collectionfolderpath = CollectionsCore::collectionUUID2FolderpathOrNull(collectionuuid)
                    targetFolder = CommonsUtils::newBinArchivesFolderpath()
                    FileUtils.mv(collectionfolderpath, targetFolder)
                end
                return
            end
            if menuChoice == menuItem4 then
                CollectionsCore::setCollectionStyle(collectionuuid, "PROJECT")
                return
            end
            if menuChoice == menuItem3 then
                CollectionsCore::setCollectionStyle(collectionuuid, "THREAD")
                return
            end
            if menuChoice == menuItem6 then
                CollectionsCore::startCollection(collectionuuid)
                return
            end
            if menuChoice == menuItem7 then
                CollectionsCore::stopCollection(collectionuuid)
                return
            end
            if menuChoice == menuItem8 then
                timespan = 3600*LucilleCore::askQuestionAnswerAsString("hours: ").to_f
                GenericTimeTracking::addTimeInSeconds(collectionuuid, timespan)
                return
            end
            # By now, menuChoice is a catalyst object
            object = menuChoice
            CommonsUtils::doPresentObjectInviteAndExecuteCommand(object)
        }
    end

    def self.startCollection(collectionuuid)
        return if GenericTimeTracking::status(collectionuuid)[0]
        GenericTimeTracking::start(collectionuuid)
        GenericTimeTracking::start(CATALYST_COMMON_AGENTCOLLECTIONS_METRIC_GENERIC_TIME_TRACKING_KEY)
        # Now we need to start the time commitment point against that collection, if any
        TimeCommitments::getItems()
        .select{|item|
            item["33be3505:collection-uuid"]==collectionuuid
        }
        .select{|item|
            !item["is-running"]
        }
        .first(1)
        .each{|item|
            TimeCommitments::saveItem(TimeCommitments::startItem(item))
        }
    end

    def self.stopCollection(collectionuuid)
        GenericTimeTracking::stop(collectionuuid)
        GenericTimeTracking::stop(CATALYST_COMMON_AGENTCOLLECTIONS_METRIC_GENERIC_TIME_TRACKING_KEY)
        # Now we need to start the time commitment point against that collection, if any
        TimeCommitments::getItems()
        .select{|item|
            item["33be3505:collection-uuid"]==collectionuuid
        }
        .select{|item|
            item["is-running"]
        }
        .first(1)
        .each{|item|
            TimeCommitments::saveItem(TimeCommitments::stopItem(item))
        }
    end

    def self.completeCollection(collectionuuid)
        folderpath = CollectionsCore::collectionUUID2FolderpathOrNull(uuid)
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
        if CollectionsCore::collectionCatalystObjectUUIDsThatAreAlive(collectionuuid).size>0 then
            puts "You cannot complete this item because it has objects"
            LucilleCore::pressEnterToContinue()
            return
        end
        GenericTimeTracking::stop(collectionuuid)
        GenericTimeTracking::stop(CATALYST_COMMON_AGENTCOLLECTIONS_METRIC_GENERIC_TIME_TRACKING_KEY)
        CollectionsCore::sendCollectionToBinTimeline(collectionuuid)
    end

    def self.ui_CollectionsDive()
        loop {
            toString = lambda{ |collectionuuid| 
                "#{CollectionsCore::getCollectionStyle(collectionuuid).ljust(8)} : #{CollectionsCore::collectionUUID2NameOrNull(collectionuuid)}"
            }
            collectionuuid = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("threads", CollectionsCore::collectionsUUIDs(), toString)
            break if collectionuuid.nil?
            CollectionsCore::ui_CollectionDive(collectionuuid)
        }
    end

    def self.interactivelySelectCollectionUUIDOrNUll()
        LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("collection", CollectionsCore::collectionsUUIDs(), lambda{ |collectionuuid| CollectionsCore::collectionUUID2NameOrNull(collectionuuid) })
    end

end