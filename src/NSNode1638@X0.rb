
# encoding: UTF-8

class NSNode1638

    # NSNode1638::commitDatapointToDiskOrNothingReturnBoolean(datapoint)
    def self.commitDatapointToDiskOrNothingReturnBoolean(datapoint)
        NyxObjects2::put(datapoint)
        true
    end

    # NSNode1638::datapoints()
    def self.datapoints()
        NyxObjects2::getSet("0f555c97-3843-4dfe-80c8-714d837eba69")
    end

    # NSNode1638::getDataPointParents(datapoint)
    def self.getDataPointParents(datapoint)
        Arrows::getSourcesForTarget(datapoint)
    end

    # NSNode1638::selectOneLocationOnTheDesktopOrNull()
    def self.selectOneLocationOnTheDesktopOrNull()
        desktopLocations = LucilleCore::locationsAtFolder("#{ENV['HOME']}/Desktop")
                            .select{|filepath| filepath[0,1] != '.' }
                            .select{|filepath| File.basename(filepath) != 'pascal.png' }
                            .select{|filepath| File.basename(filepath) != 'Todo-Inbox' }
                            .sort
        LucilleCore::selectEntityFromListOfEntitiesOrNull("filepath", desktopLocations, lambda{ |location| File.basename(location) })
    end

    # NSNode1638::issueLine(line)
    def self.issueLine(line)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "line",
            "line"       => line
        }
        NyxObjects2::put(object)
        object
    end

    # NSNode1638::issueNyxDirectory(nyxDirectoryName)
    def self.issueNyxDirectory(nyxDirectoryName)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "NyxDirectory",
            "name"       => nyxDirectoryName
        }
        NyxObjects2::put(object)
        object
    end

    # NSNode1638::issueNyxFile(nyxFileName)
    def self.issueNyxFile(nyxFileName)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "NyxFile",
            "name"       => nyxFileName
        }
        NyxObjects2::put(object)
        object
    end

    # NSNode1638::issueSet(setuuid)
    def self.issueSet(setuuid)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "set",
            "setuuid"   => setuuid
        }
        NyxObjects2::put(object)
        object
    end

    # NSNode1638::issueNewPointInteractivelyOrNull()
    def self.issueNewPointInteractivelyOrNull()
        types = ["line", "url", "text", "NyxFile", "NGX15", "set"]
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", types)
        return if type.nil?
        if type == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            return nil if line.size == 0
            return NSNode1638::issueLine(line)
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            return nil if url.size == 0
            return Quark::issueUrl(url)
        end
        if type == "text" then
            nyxfilename = "NyxFile-#{SecureRandom.uuid}.txt"
            filepath = "/Users/pascal/Galaxy/Timeline/#{Time.new.strftime("%Y")}/Catalyst-Elements/#{Time.new.strftime("%Y-%m")}/#{nyxfilename}"
            if !File.exists?(File.dirname(filepath)) then
                FileUtils.mkpath(File.dirname(filepath))
            end
            FileUtils.touch(filepath)
            system("open '#{filepath}'")
            LucilleCore::pressEnterToContinue()
            return NSNode1638::issueNyxFile(nyxfilename)
        end
        if type == "NyxFile" then
            op = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", ["nyxfilename already exists", "issue new nyxfilename"])
            return nil if op.nil?
            if op == "nyxfilename already exists" then
                nyxfilename = LucilleCore::askQuestionAnswerAsString("nyxfile name: ")
                return nil if nyxfilename.size == 0
            end
            if op == "issue new nyxfilename" then
                extention = LucilleCore::askQuestionAnswerAsString("extension with dot: ")
                return nil if extention == ""
                nyxfilename = "NyxFile-#{SecureRandom.uuid}#{extention}"
                puts "nyxfilename: #{nyxfilename}"
                LucilleCore::pressEnterToContinue()
            end
            return NSNode1638::issueNyxFile(nyxfilename)
        end
        if type == "NyxDirectory" then
            nyxDirectoryName = "NyxDirectory-#{SecureRandom.uuid}"
            puts "nyxDirectoryName: #{nyxDirectoryName}"
            LucilleCore::pressEnterToContinue()
            return NSNode1638::issueNyxDirectory(nyxDirectoryName)
        end
        if type == "set" then
            set = Sets::selectExistingSetOrMakeNewOneOrNull()
            return nil if set.nil?
            return NSNode1638::issueSet(set["uuid"])
        end
    end

    # NSNode1638::toString(datapoint)
    def self.toString(datapoint)
        suffixWithPadding = lambda {|datapoint|
            if datapoint["type"] == "NyxFile" then
                return " ( #{datapoint["name"]} )"
            end
            if datapoint["type"] == "NyxDirectory" then
                return " ( #{datapoint["name"]} )"
            end
            if datapoint["type"] == "NGX15" then
                return " ( #{datapoint["ngx15"]} )"
            end
            ""
        }

        if datapoint["description"] then
            return "[#{datapoint["type"]}] #{datapoint["description"]}#{suffixWithPadding.call(datapoint)}"
        end
        if datapoint["type"] == "line" then
            return "[#{datapoint["type"]}] #{datapoint["line"]}"
        end
        if datapoint["type"] == "NyxFile" then
            return "[#{datapoint["type"]}] #{datapoint["name"]}"
        end
        if datapoint["type"] == "NyxDirectory" then
            return "[#{datapoint["type"]}] #{datapoint["name"]}"
        end
        if datapoint["type"] == "NGX15" then
            return "[#{datapoint["type"]}] #{datapoint["ngx15"]}"
        end
        if datapoint["type"] == "set" then
            setuuid = datapoint["setuuid"]
            set = NyxObjects2::getOrNull(setuuid)
            setAsString = set ? Sets::toString(set) : "(set not found: uuid: #{setuuid})"
            return "[datapoint: #{datapoint["type"]}] #{setAsString}"
        end
        puts datapoint
        raise "[NSNode1638 error d39378dc]"
    end

    # NSNode1638::opendatapoint(datapoint)
    def self.opendatapoint(datapoint)
        if datapoint["type"] == "line" then
            puts "line: #{datapoint["line"]}"
            LucilleCore::pressEnterToContinue()
            return nil
        end
        if datapoint["type"] == "NyxFile" then
            location = NSNode1638_FileSystemElements::getLocationByAllMeansOrNull(datapoint)
            if location then
                puts "filepath: #{location}"
                system("open '#{location}'")
                LucilleCore::pressEnterToContinue()
            else
                puts "I could not determine the location of #{datapoint["name"]}"
                LucilleCore::pressEnterToContinue()
            end
            return nil
        end
        if datapoint["type"] == "NyxDirectory" then
            location = NSNode1638_FileSystemElements::getLocationByAllMeansOrNull(datapoint)
            if location then
                puts "target file '#{location}'"
                system("open '#{File.dirname(location)}'")
                LucilleCore::pressEnterToContinue()
            else
                puts "I could not determine the location of #{datapoint["name"]}"
                LucilleCore::pressEnterToContinue()
            end
            return nil
        end
        if datapoint["type"] == "NGX15" then
            location = GalaxyFinder::uniqueStringToLocationOrNull(datapoint["ngx15"])
            if location then
                puts "target file '#{location}'"
                system("open '#{File.dirname(location)}'")
                LucilleCore::pressEnterToContinue()
            else
                puts "I could not determine the location of #{datapoint["ngx15"]}"
                LucilleCore::pressEnterToContinue()
            end
            return nil
        end
        if datapoint["type"] == "set" then
             setuuid = datapoint["setuuid"]
             set = NyxObjects2::getOrNull(setuuid)
             return if set.nil?
             Sets::landing(set)
        end
        puts datapoint
        raise "[NSNode1638 error e12fc718]"
    end

    # NSNode1638::landing(datapoint)
    def self.landing(datapoint)
        loop {

            return if NyxObjects2::getOrNull(datapoint["uuid"]).nil?

            system("clear")

            mx = LCoreMenuItemsNX1.new()

            source = Arrows::getSourcesForTarget(datapoint)
            source.each{|source|
                mx.item(
                    "source: #{NyxObjectInterface::toString(source)}",
                    lambda { NyxObjectInterface::landing(source) }
                )
            }

            puts ""

            puts NSNode1638::toString(datapoint).green
            puts "uuid: #{datapoint["uuid"]}".yellow
            puts "date: #{NyxObjectInterface::getObjectReferenceDateTime(datapoint)}".yellow

            puts ""

            mx.item(
                "open".yellow,
                lambda {
                    NSNode1638::opendatapoint(datapoint)
                }
            )

            mx.item("set/update description".yellow, lambda {
                description = Miscellaneous::editTextSynchronously(datapoint["description"] || "").strip
                return if description == ""
                datapoint["description"] = description
                NSNode1638::commitDatapointToDiskOrNothingReturnBoolean(datapoint)
            })

            mx.item("set/update datetime".yellow, lambda {
                datetime = Miscellaneous::editTextSynchronously(datapoint["referenceDateTime"] || Time.new.utc.iso8601).strip
                datapoint["referenceDateTime"] = datetime
                NSNode1638::commitDatapointToDiskOrNothingReturnBoolean(datapoint)
            })

            mx.item("add to set".yellow, lambda {
                set = Sets::selectExistingSetOrMakeNewOneOrNull()
                return if set.nil?
                Arrows::issueOrException(set, datapoint)
            })

            mx.item("transmute datapoint".yellow, lambda {
                newpoint = NSNode1638::issueNewPointInteractivelyOrNull()
                NyxObjects2::destroy(newpoint)
                newpoint["uuid"] = datapoint["uuid"]
                NSNode1638::commitDatapointToDiskOrNothingReturnBoolean(newpoint)
            })

            mx.item("to cube system".yellow, lambda {
                CubeTransformers::sendDatapointToCubeSystem(datapoint)
            })

            mx.item("destroy".yellow, lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy '#{NSNode1638::toString(datapoint)}': ") then
                    NSNode1638::datapointTerminationProtocolReturnBoolean(datapoint)
                end
            })

            puts ""

            Arrows::getTargetsForSource(datapoint).each{|target|
                menuitems.item(
                    "target: #{NyxObjectInterface::toString(target)}",
                    lambda { NyxObjectInterface::landing(target) }
                )
            }

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # NSNode1638::datapointTerminationProtocolReturnBoolean(datapoint)
    def self.datapointTerminationProtocolReturnBoolean(datapoint)

        puts "Destroying datapoint: #{NSNode1638::toString(datapoint)}"

        if datapoint["type"] == "line" then

        end
        if datapoint["type"] == "NyxFile" then
            location = NSNode1638_FileSystemElements::getLocationByAllMeansOrNull(datapoint)
            if location then
                puts "NyxFile: #{location}"
            end
            if LucilleCore::askQuestionAnswerAsBoolean("destroy target NyxFile file ? ") then
                if location then
                    FileUtils.rm(location)
                else
                    puts "Failure to find the target file."
                    if !LucilleCore::askQuestionAnswerAsBoolean("Is this expected ? ") then
                        puts "Very well. Exiting."
                        exit
                    end
                end
            end
        end
        if datapoint["type"] == "NyxDirectory" then
            puts "Datapoint is NyxDirectory, we are going to remove the NyxDirectory file..."
            location = NSNode1638_FileSystemElements::getLocationByAllMeansOrNull(datapoint)
            if location then
                puts "NyxDirectory: #{location}"
                puts "Actually I am going to let you do that..."
                sleep 3
                system("open '#{File.dirname(location)}'")
                LucilleCore::pressEnterToContinue()
            else
                puts "Failure to find the file."
                if !LucilleCore::askQuestionAnswerAsBoolean("Is this expected ? ") then
                    puts "Very well. Exiting."
                    exit
                end
            end
        end
        if datapoint["type"] == "NGX15" then
            location = GalaxyFinder::uniqueStringToLocationOrNull(datapoint["ngx15"])
            if location then
                puts "Target file '#{location}'"
                puts "Delete as appropriate"
                system("open '#{File.dirname(location)}'")
                LucilleCore::pressEnterToContinue()
            else
                puts "I could not determine the location of #{datapoint["ngx15"]}"
                if !LucilleCore::askQuestionAnswerAsBoolean("Continue with datapoint deletion ? ") then
                    return
                end
            end
        end

        if datapoint["type"] == "set" then

        end

        NyxObjects2::destroy(datapoint)

        true
    end
end
