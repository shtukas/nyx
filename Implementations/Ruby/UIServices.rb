# encoding: UTF-8

class NereidInterface

    # Duck Patching

    # NereidInterface::accessSpecialXStream(messageDescription, messageCommands, input)
    def self.accessSpecialXStream(messageDescription, messageCommands, input)

        element = NereidInterface::inputToElementOrNull(input, "access")
        return if element.nil?

        if element["type"] == "Line" then
            return LucilleCore::askQuestionAnswerAsString("#{messageDescription} ; #{messageCommands} : ")
        end
        if element["type"] == "Url" then
            NereidUtils::openUrl(element["payload"])
            return LucilleCore::askQuestionAnswerAsString("#{messageDescription} ; #{messageCommands} : ")
        end
        if element["type"] == "Text" then
            puts messageDescription
            type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["read-only", "read-write"])
            return if type.nil?
            if type == "read-only" then
                text = NereidBinaryBlobsService::getBlobOrNull(element["payload"])
                filepath = "/Users/pascal/Desktop/#{element["uuid"]}.txt"
                File.open(filepath, "w"){|f| f.write(text) }
                puts "I have exported the file at '#{filepath}'"
            end
            if type == "read-write" then
                text = NereidBinaryBlobsService::getBlobOrNull(element["payload"])
                text = NereidUtils::editTextSynchronously(text)
                element["payload"] = NereidBinaryBlobsService::putBlob(text)
                NereidDatabase::insertElement(element)
            end
            return LucilleCore::askQuestionAnswerAsString("#{messageCommands} : ")
        end
        if element["type"] == "ClickableType" then
            puts messageDescription
            puts "opening file '#{element["payload"]}'"
            type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["read-only", "read-write"])
            if type == "read-only" then
                blobuuid, extension = element["payload"].split("|")
                filepath = "/Users/pascal/Desktop/#{element["uuid"]}#{extension}"
                blob = NereidBinaryBlobsService::getBlobOrNull(blobuuid)
                File.open(filepath, "w"){|f| f.write(blob) }
                puts "I have exported the file at '#{filepath}'"
            end
            if type == "read-write" then
                blobuuid, extension = element["payload"].split("|")
                filepath = "/Users/pascal/Desktop/#{element["uuid"]}#{extension}"
                blob = NereidBinaryBlobsService::getBlobOrNull(blobuuid)
                File.open(filepath, "w"){|f| f.write(blob) }
                puts "I have exported the file at '#{filepath}'"
                puts "When done, you will enter the filename of the replacement"
                LucilleCore::pressEnterToContinue()
                filename = LucilleCore::askQuestionAnswerAsString("desktop filename (empty to abort): ")
                return if filename == ""
                filepath = "/Users/pascal/Desktop/#{filename}"
                return nil if !File.exists?(filepath)

                nhash = NereidBinaryBlobsService::putBlob(IO.read(filepath))
                dottedExtension = File.extname(filename)
                payload = "#{nhash}|#{dottedExtension}"

                element["payload"] = payload
                NereidDatabase::insertElement(element)
            end
            return LucilleCore::askQuestionAnswerAsString("#{messageCommands} : ")
        end
        if element["type"] == "AionPoint" then
            puts messageDescription
            puts "opening aion point '#{element["payload"]}'"
            type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["read-only", "read-write"])
            if type == "read-only" then
                nhash = element["payload"]
                targetReconstructionFolderpath = "/Users/pascal/Desktop"
                AionCore::exportHashAtFolder(NereidElizabeth.new(), nhash, targetReconstructionFolderpath)
                puts "Export completed"
            end
            if type == "read-write" then
                nhash = element["payload"]
                targetReconstructionFolderpath = "/Users/pascal/Desktop"
                AionCore::exportHashAtFolder(NereidElizabeth.new(), nhash, targetReconstructionFolderpath)
                puts "Export completed"
                puts "When done, you will enter the location name of the replacement"
                LucilleCore::pressEnterToContinue()
                locationname = LucilleCore::askQuestionAnswerAsString("desktop location name: ")
                location = "/Users/pascal/Desktop/#{locationname}"
                return nil if !File.exists?(location)
                payload = AionCore::commitLocationReturnHash(NereidElizabeth.new(), location)
                element["payload"] = payload
                NereidDatabase::insertElement(element)
            end
            return LucilleCore::askQuestionAnswerAsString("#{messageCommands} : ")
        end
        if element["type"] == "FSUniqueString" then
            puts messageDescription
            location = NereidGalaxyFinder::uniqueStringToLocationOrNull(element["payload"])
            if location.nil? then
                puts "I could not determine location for file system unique string: #{element["payload"]}"
                LucilleCore::pressEnterToContinue()
            else
                if File.file?(location) then
                    option = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", ["open file", "open parent folder"])
                    return if option.nil?
                    if option == "open file" then
                        system("open '#{location}'")
                    end
                    if option == "open parent folder" then
                        system("open '#{File.dirname(location)}'")
                    end
                else
                    system("open '#{location}'")
                end
            end
            return LucilleCore::askQuestionAnswerAsString("#{messageCommands} : ")
        end
        raise "[error: d21f87c1-94e0-47fd-a1dd-421812e3957a]"
    end
end

class UIServices

    # UIServices::makeDisplayStringForCatalystListing(object)
    def self.makeDisplayStringForCatalystListing(object)
        body = object["body"]
        lines = body.lines.to_a
        if lines.size == 1 then
            "#{lines.first}"
        else
            "#{lines.shift}" + lines.map{|line|  "             #{line}"}.join()
        end
    end

    # UIServices::servicesFront()
    def self.servicesFront()
        loop {
            system("clear")

            ms = LCoreMenuItemsNX1.new()

            ms.item("Calendar", lambda { Calendar::main() })

            ms.item("Waves", lambda { Waves::main() })

            ms.item("DxThreads", lambda { DxThreads::main() })

            puts ""

            ms.item("new wave", lambda { Waves::issueNewWaveInteractivelyOrNull() })            

            ms.item("new quark", lambda { Patricia::possiblyNewQuarkToPossiblyUnspecifiedDxThread(nil, nil) })    

            puts ""

            ms.item("dangerously edit a NSCoreObject by uuid", lambda { 
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                return if uuid == ""
                object = NSCoreObjects::getOrNull(uuid)
                return if object.nil?
                object = Miscellaneous::editTextSynchronously(JSON.pretty_generate(object))
                object = JSON.parse(object)
                NSCoreObjects::put(object)
            })

            ms.item("dangerously delete a NSCoreObject by uuid", lambda { 
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                object = NSCoreObjects::getOrNull(uuid)
                return if object.nil?
                puts JSON.pretty_generate(object)
                return if !LucilleCore::askQuestionAnswerAsBoolean("delete ? : ")
                NSCoreObjects::destroy(object)
            })

            puts ""

            ms.item(
                "NSGarbageCollection::run()",
                lambda { NSGarbageCollection::run() }
            )

            ms.item(
                "Print Generation Speed Report", 
                lambda { CatalystObjectsOperator::generationSpeedReport() }
            )

            status = ms.promptAndRunSandbox()
            break if !status
        }
    end

    # UIServices::xStreamRun()
    def self.xStreamRun()

        counter1 = 0

        time1 = Time.new

        shouldExitXStreamRun = lambda {|time1| Time.new.to_s[0, 13] != time1.to_s[0, 13] }

        Calendar::calendarItems()
            .sort{|i1, i2| i1["date"]<=>i2["date"] }
            .each{|item|
                Calendar::toString(item).yellow
            }

        DxThreads::dxthreads()
            .select{|dx| DxThreads::completionRatio(dx) < 1 }
            .sort{|dx1, dx2| DxThreads::completionRatio(dx1) <=> DxThreads::completionRatio(dx2) }
            .each{|dxthread|
                puts DxThreads::toStringWithAnalytics(dxthread).yellow
            }

        CatalystObjectsOperator::getCatalystListingObjectsOrdered()
            .each{|object|
                puts ""
                puts UIServices::makeDisplayStringForCatalystListing(object)
                object["access"].call()
                return if shouldExitXStreamRun.call(time1)
            }

        puts ""

        processQuark = lambda {|dxthread, quark|
            element = NereidInterface::getElementOrNull(quark["nereiduuid"])
            return if element.nil?
            t1 = Time.new.to_f                    
            input = NereidInterface::accessSpecialXStream("running: #{DxThreads::dxThreadAndTargetToString(dxthread, quark).green}", "( done ; pause ; landing ; empty for next ; / )", quark["nereiduuid"])
            timespan = Time.new.to_f - t1
            Bank::put(quark["uuid"], timespan)
            Bank::put(dxthread["uuid"], timespan)
            if input == "done" then
                Quarks::destroyQuarkAndNereidContent(quark)
                return
            end
            if input == "pause" then
                puts "paused"
                LucilleCore::pressEnterToContinue()
                processQuark.call(quark)
                return
            end
            if input == "landing" then
                NereidInterface::landing(quark["nereiduuid"])
                return
            end
            if input == "/" then
                UIServices::servicesFront()
            end
        }

        runDxThread = lambda{|dxthread, depth|
            Arrows::getTargetsForSource(dxthread)
                .sort{|t1, t2| Ordinals::getObjectOrdinal(t1) <=> Ordinals::getObjectOrdinal(t2) }
                .first(depth)
                .each_with_index{|quark, indx|
                    counter1 = counter1 + 1
                    processQuark.call(dxthread, quark)
                    if (indx % 10 == 0) then
                        puts "[#{counter1}] Interruption opportunity".red
                        LucilleCore::pressEnterToContinue()
                    end
                    return if shouldExitXStreamRun.call(time1)
                }
        }

        DxThreads::getTopThreads()
            .each{|dxthread| runDxThread.call(dxthread, 10) }

        runDxThread.call(DxThreads::getStream(), 100)

    end

    # UIServices::standardTodoListingLoop()
    def self.standardTodoListingLoop()

        Quarks::quarks().each{|quark|
            if !Arrows::getSourcesForTarget(quark).any?{|parent| Patricia::isDxThread(parent) } then
                puts "Adding orphan quark to DxThread: #{Patricia::toString(quark)}"
                LucilleCore::pressEnterToContinue()
                Patricia::moveTargetToNewDxThread(quark, nil)
                exit
            end
        }

        Ordinals::getOrdinalItems().each{|item|
            if NSCoreObjects::getOrNull(item["uuid"]).nil? then
                puts "ordinals database garbage collection, unknown uuid: #{item["uuid"]}"
                LucilleCore::pressEnterToContinue()
                Ordinals::deleteRecord(item["uuid"])
            end
        }

        Thread.new {
            loop {
                sleep 1800
                if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("f5f52127-c140-4c59-85a2-8242b546fe1f", 3600) then
                    system("#{File.dirname(__FILE__)}/../../vienna-import")
                end
            }
        }

        UIServices::xStreamRun()
    end
end


