
# encoding: UTF-8

class NSNode1638

    # NSNode1638::commitDatapointToDiskOrNothingReturnBoolean(datapoint)
    def self.commitDatapointToDiskOrNothingReturnBoolean(datapoint)
        if datapoint["type"] == "NyxFSPoint001" then
            location = NSNode1638NyxElementLocation::getLocationByAllMeansOrNull(datapoint)
            return false if location.nil?
            File.open(location, "w"){|f| f.puts(JSON.pretty_generate(datapoint)) }
        end
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

    # NSNode1638::issueUrl(url)
    def self.issueUrl(url)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "url",
            "url"        => url
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

    # NSNode1638::issueNyxFSPointOrNull(description, parentfolderpath, filenameuuid)
    def self.issueNyxFSPointOrNull(description, parentfolderpath, filenameuuid)
        return nil if !File.exists?(parentfolderpath)
        return nil if !File.directory?(parentfolderpath)
        filename = "NyxFSPoint001-#{filenameuuid}.json"
        filepath = "#{parentfolderpath}/#{filename}"
        object = {
            "uuid"        => SecureRandom.uuid,
            "nyxNxSet"    => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"    => Time.new.to_f,
            "type"        => "NyxFSPoint001",
            "name"        => filename,
            "description" => description
        }
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(object)) }
        GalaxyFinder::registerFilenameAtLocation(filename, filepath)
        NyxObjects2::put(object)
        object
    end

    # NSNode1638::issueNewPointInteractivelyOrNull()
    def self.issueNewPointInteractivelyOrNull()
        types = ["line", "url", "text", "NyxFile", "NyxDirectory"] # We are not yet interactively issuing NyxFSPoint001
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
            return NSNode1638::issueUrl(url)
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
            if datapoint["type"] == "NyxFSPoint001" then
                return " ( #{datapoint["name"]} )"
            end
            ""
        }

        if datapoint["description"] then
            return "[#{datapoint["type"]}] #{datapoint["description"]}#{suffixWithPadding.call(datapoint)}"
        end
        if datapoint["type"] == "line" then
            return "[#{datapoint["type"]}] #{datapoint["line"]}"
        end
        if datapoint["type"] == "url" then
            return "[#{datapoint["type"]}] #{datapoint["url"]}"
        end
        if datapoint["type"] == "NyxFile" then
            return "[#{datapoint["type"]}] #{datapoint["name"]}"
        end
        if datapoint["type"] == "NyxDirectory" then
            return "[#{datapoint["type"]}] #{datapoint["name"]}"
        end
        if datapoint["type"] == "NyxFSPoint001" then
            return "[#{datapoint["type"]}] #{datapoint["name"]}"
        end
        puts datapoint
        raise "[NSNode1638 error d39378dc]"
    end

    # NSNode1638::opendatapoint(datapoint)
    def self.opendatapoint(datapoint)
        if datapoint["type"] == "line" then
            puts "line: #{datapoint["line"]}"
            return nil
        end
        if datapoint["type"] == "url" then
            puts "url: #{datapoint["url"]}"
            system("open '#{datapoint["url"]}'")
            return nil
        end
        if datapoint["type"] == "NyxFile" then
            location = NSNode1638NyxElementLocation::getLocationByAllMeansOrNull(datapoint)
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
            location = NSNode1638NyxElementLocation::getLocationByAllMeansOrNull(datapoint)
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
        if datapoint["type"] == "NyxFSPoint001" then
            location = NSNode1638NyxElementLocation::getLocationByAllMeansOrNull(datapoint)
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
        puts datapoint
        raise "[NSNode1638 error e12fc718]"
    end

    # NSNode1638::landing(datapoint)
    def self.landing(datapoint)
        loop {

            return if NyxObjects2::getOrNull(datapoint["uuid"]).nil?

            system("clear")

            mx = LCoreMenuItemsNX1.new()

            islands = Arrows::getSourceForTargetOfGivenNyxType(datapoint, "287041db-39ac-464c-b557-2f172e721111")
            islands.each{|island|
                mx.item(
                    Islands::toString(island),
                    lambda { Islands::landing(island) }
                )
            }
            if islands.size>0 then
                puts ""
            end

            tags = Arrows::getSourcesForTarget(datapoint).select{|object| NyxObjectInterface::isTag(object) }
            tags.each{|tag|
                mx.item(
                    Tags::toString(tag),
                    lambda { 
                        Tags::landing(tag)
                    }
                )
            }
            if tags.size>0 then
                puts ""
            end

            puts NSNode1638::toString(datapoint).green
            puts ""

            mx.item(
                "open",
                lambda {
                    NSNode1638::opendatapoint(datapoint)
                }
            )

            puts ""
            puts "uuid: #{datapoint["uuid"]}".yellow
            puts "date: #{NyxObjectInterface::getObjectReferenceDateTime(datapoint)}".yellow

            puts ""

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

            mx.item("transmute datapoint".yellow, lambda {
               if datapoint["type"] == "NyxFSPoint001" then
                    puts "Sorry, I do not know how to transmute out of a NyxFSPoint001."
                    LucilleCore::pressEnterToContinue()
                    return
                end
                newpoint = NSNode1638::issueNewPointInteractivelyOrNull()
                NyxObjects2::destroy(newpoint)
                newpoint["uuid"] = datapoint["uuid"]
                NSNode1638::commitDatapointToDiskOrNothingReturnBoolean(newpoint)
            })

            mx.item("to cube system".yellow, lambda {
                CubeTransformers::sendDatapointToCubeSystem(datapoint)
            })

            mx.item("add tag".yellow, lambda {
                payload = LucilleCore::askQuestionAnswerAsString("tag payload: ")
                return if payload == ""
                tag = Tags::issue(payload)
                Arrows::issueOrException(tag, datapoint)
            })

            mx.item("destroy".yellow, lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy '#{NSNode1638::toString(datapoint)}': ") then
                    NSNode1638::datapointTerminationProtocolReturnBoolean(datapoint)
                end
            })

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
        if datapoint["type"] == "url" then

        end
        if datapoint["type"] == "NyxFile" then
            location = NSNode1638NyxElementLocation::getLocationByAllMeansOrNull(datapoint)
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
            location = NSNode1638NyxElementLocation::getLocationByAllMeansOrNull(datapoint)
            if location then
                puts "NyxDirectory: #{location}"
            end
            if location then
                if File.dirname(File.dirname(location)) == "/Users/pascal/Galaxy/DataBank/Catalyst/Asteroids-Items" then
                    puts "Found NyxDirectory: #{location}"
                    parent = File.dirname(location)
                    puts "Going to remove the parent folder: #{parent}"
                    LucilleCore::removeFileSystemLocation(parent)
                else
                    # We are in the interesting case of an asteroid with a NyxHud child which is not in Asteroids-Items
                    puts "Actually I am going to let you do that..."
                    sleep 3
                    system("open '#{File.dirname(location)}'")
                    LucilleCore::pressEnterToContinue()
                end
            else
                puts "Failure to find the file."
                if !LucilleCore::askQuestionAnswerAsBoolean("Is this expected ? ") then
                    puts "Very well. Exiting."
                    exit
                end
            end
        end
        if datapoint["type"] == "NyxFSPoint001" then
            location = NSNode1638NyxElementLocation::getLocationByAllMeansOrNull(datapoint)
            if location then
                puts "NyxFSPoint001: #{location}"
            end
            puts File.dirname(File.dirname(location))
            return false if location.nil?
            FileUtils.rm(location)
            puts File.dirname(File.dirname(location))
            if File.dirname(File.dirname(location)) == "/Users/pascal/Galaxy/DataBank/Catalyst/Asteroids-Items" then
                parent = File.dirname(location)
                puts "We are in asteroids land. Going to remove the parent folder: #{parent}"
                LucilleCore::removeFileSystemLocation(parent)
            end
        end

        NyxObjects2::destroy(datapoint)

        true
    end
end
