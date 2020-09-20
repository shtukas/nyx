
# encoding: UTF-8

class NSNode1638

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

    # NSNode1638::issueNavigation(description)
    def self.issueNavigation(description)
        object = {
            "uuid"        => SecureRandom.uuid,
            "nyxNxSet"    => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"    => Time.new.to_f,
            "type"        => "navigation",
            "description" => description
        }
        NyxObjects2::put(object)
        object
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
        types = ["navigation", "line", "url", "text", "NyxFile", "NyxDirectory"] # We are not yet interactively issuing NyxFSPoint001
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", types)
        return if type.nil?
        if type == "navigation" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return nil if description.size == 0
            return NSNode1638::issueNavigation(description)
        end
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

    # NSNode1638::toStringUseTheForce(datapoint)
    def self.toStringUseTheForce(datapoint)

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
        if datapoint["type"] == "navigation" then
            return "[#{datapoint["type"]}] {no description}"
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

    # NSNode1638::toString(datapoint, useCachedValue = true)
    def self.toString(datapoint, useCachedValue = true)
        cacheKey = "e7eb4787-0cfd-4184-a286-2dbec629d9eb:#{datapoint["uuid"]}"
        if useCachedValue then
            str = KeyValueStore::getOrNull(nil, cacheKey)
            return str if str
        end
        str = NSNode1638::toStringUseTheForce(datapoint)
        KeyValueStore::set(nil, cacheKey, str)
        str
    end

    # NSNode1638::opendatapoint(datapoint)
    def self.opendatapoint(datapoint)
        if datapoint["type"] == "navigation" then
            return nil
        end
        if datapoint["type"] == "line" then
            puts "line: #{datapoint["line"]}"
            if LucilleCore::askQuestionAnswerAsBoolean("edit line ? : ", false) then
                line = datapoint["line"]
                line = Miscellaneous::editTextSynchronously(line).strip
                return NSNode1638::issueLine(line)
            end
            return nil
        end
        if datapoint["type"] == "url" then
            puts "url: #{datapoint["url"]}"
            system("open '#{datapoint["url"]}'")
            if LucilleCore::askQuestionAnswerAsBoolean("edit url ? : ", false) then
                url = datapoint["url"]
                url = Miscellaneous::editTextSynchronously(url).strip
                return NSNode1638::issueUrl(url)
            end
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

            interpreter = Interpreter.new()

            parents = Arrows::getSourcesForTarget(datapoint)
            parents.each{|o|
                    interpreter.indexDrivenMenuItem("parent: #{GenericObjectInterface::toString(o, false)}", lambda { 
                        GenericObjectInterface::landing(o)
                    })
                }
            if parents.size>0 then
                puts ""
            end

            puts NSNode1638::toString(datapoint, false).green
            if datapoint["type"] != "navigation" then
                interpreter.indexDrivenMenuItem("open", lambda {
                    NSNode1638::opendatapoint(datapoint)
                })
            end

            puts ""

            targets = Arrows::getTargetsForSource(datapoint)
            targets = GenericObjectInterface::applyDateTimeOrderToObjects(targets)
            targets.each{|o|
                interpreter.indexDrivenMenuItem("child : #{GenericObjectInterface::toString(o, false)}", lambda { 
                    GenericObjectInterface::landing(o)
                })
            }

            if targets.size>0 then
                puts ""
            end

            interpreter.registerExactCommand("metadata", lambda {
                puts "#{NSNode1638::toString(datapoint, false)}"
                puts "uuid: #{datapoint["uuid"]}".yellow
                puts "date: #{GenericObjectInterface::getObjectReferenceDateTime(datapoint)}".yellow
                LucilleCore::pressEnterToContinue()
            })

            interpreter.registerExactCommand("description", lambda {
                description = Miscellaneous::editTextSynchronously(datapoint["description"] || "").strip
                return if description == ""
                datapoint["description"] = description
                NyxObjects2::put(datapoint)
            })

            interpreter.registerExactCommand("datetime", lambda {
                datetime = Miscellaneous::editTextSynchronously(datapoint["referenceDateTime"] || Time.new.utc.iso8601).strip
                datapoint["referenceDateTime"] = datetime
                NyxObjects2::put(datapoint)
            })

            interpreter.registerExactCommand("remove [this] as intermediary node", lambda {
                puts "intermediary node removal simulation"
                Arrows::getSourcesForTarget(datapoint).each{|upstreamnode|
                    puts "upstreamnode   : #{GenericObjectInterface::toString(upstreamnode)}"
                }
                Arrows::getTargetsForSource(datapoint).each{|downstreamobject|
                    puts "downstream object: #{GenericObjectInterface::toString(downstreamobject)}"
                }
                return if !LucilleCore::askQuestionAnswerAsBoolean("confirm removing as intermediary node ? ")
                Arrows::getSourcesForTarget(datapoint).each{|upstreamnode|
                    Arrows::getTargetsForSource(datapoint).each{|downstreamobject|
                        Arrows::issueOrException(upstreamnode, downstreamobject)
                    }
                }
                NyxObjects2::destroy(datapoint)
            })

            interpreter.registerExactCommand("transmute", lambda {
                newpoint = NSNode1638::issueNewPointInteractivelyOrNull()
                NyxObjects2::destroy(newpoint)
                newpoint["uuid"] = datapoint["uuid"]
                NyxObjects2::put(newpoint)
            })

            interpreter.registerExactCommand("destroy [this]", lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy '#{NSNode1638::toString(datapoint)}': ") then
                    NyxObjects2::destroy(datapoint)
                end
            })

            interpreter.registerExactCommand("attach new parent", lambda {
                n = NSNode1638Extended::selectOneExistingDatapointOrMakeANewOneOrNull()
                return if n.nil?
                Arrows::issueOrException(n, datapoint)
            })

            interpreter.registerExactCommand("detach parent", lambda {
                ns = LucilleCore::selectEntityFromListOfEntitiesOrNull("parent", Arrows::getSourcesForTarget(node), lambda{|o| GenericObjectInterface::toString(o) })
                return if ns.nil?
                Arrows::unlink(ns, datapoint)
            })

            interpreter.registerExactCommand("issue new child", lambda {
                child = NSNode1638::issueNewPointInteractivelyOrNull()
                return if child.nil?
                Arrows::issueOrException(datapoint, child)
                if child["type"] != "navigation" then
                    description = LucilleCore::askQuestionAnswerAsString("description: ")
                    if description != "" then
                        child["description"] =  description
                        NyxObjects2::put(child)
                    end
                end
            })

            interpreter.registerExactCommand("select and attach ; child", lambda {
                o = NSNode1638Extended::selectOneExistingDatapointOrMakeANewOneOrNull()
                return if o.nil?
                Arrows::issueOrException(datapoint, o)
            })

            interpreter.registerExactCommand("detach child", lambda {
                targets = Arrows::getTargetsForSource(datapoint)
                targets = GenericObjectInterface::applyDateTimeOrderToObjects(targets)
                ns = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", targets, lambda{|o| GenericObjectInterface::toString(o) })
                return if ns.nil?
                Arrows::unlink(datapoint, ns)
            })

            interpreter.registerExactCommand("select children ; move to existing/new node", lambda {
                return if Arrows::getTargetsForSource(datapoint).size == 0

                targets = Arrows::getTargetsForSource(datapoint)
                targets = GenericObjectInterface::applyDateTimeOrderToObjects(targets)

                # Selecting the nodes to moves
                selectednodes, _ = LucilleCore::selectZeroOrMore("object", [], targets, lambda{ |o| GenericObjectInterface::toString(o) })
                return if selectednodes.size == 0

                # Selecting or creating the node
                selectTargetNode = lambda { |node|
                    mode = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", ["existing child node", "new child node", "new independant node"])
                    return nil if mode.nil?
                    if mode == "existing child node" then
                        targets = Arrows::getTargetsForSource(node)
                        targets = GenericObjectInterface::applyDateTimeOrderToObjects(targets)
                        return LucilleCore::selectEntityFromListOfEntitiesOrNull("object", targets, lambda{|o| GenericObjectInterface::toString(o) })
                    end
                    if mode == "new child node" then
                        childnode = NSNode1638::issueNewPointInteractivelyOrNull()
                        return nil if childnode.nil?
                        Arrows::issueOrException(node, childnode)
                        return childnode
                    end
                    if mode == "new independant node" then
                        xnode = NSNode1638::issueNewPointInteractivelyOrNull()
                        return nil if xnode.nil?
                        return xnode
                    end
                }

                targetnode = selectTargetNode.call(datapoint)
                return if targetnode.nil?

                # TODO: return if the selected new target is one of the nodes

                # Moving the selectednodes
                selectednodes.each{|o|
                    Arrows::issueOrException(targetnode, o)
                }
                selectednodes.each{|o|
                    Arrows::unlink(datapoint, o)
                }
            })

            interpreter.registerExactCommand("help", lambda {
                commands = [
                    "metadata",
                    "description",
                    "datetime",
                    "remove [this] as intermediary node",
                    "transmute",
                    "destroy [this]",
                    "attach new parent",
                    "detach parent",
                    "issue new child",
                    "select and attach ; child",
                    "detach child",
                    "select children ; move to existing/new node",
                ]
                commands.each{|command|
                    puts "   - #{command}"
                }
                LucilleCore::pressEnterToContinue()
            })

            status = interpreter.prompt()

            break if !status
        }
    end

    # NSNode1638::destroyOrNothingReturnBoolean(datapoint)
    def self.destroyOrNothingReturnBoolean(datapoint)

        return false if !Arrows::getTargetsForSource(datapoint).empty?

        puts "Destroying datapoint: #{NSNode1638::toString(datapoint)}"

        if datapoint["type"] == "line" then

        end
        if datapoint["type"] == "url" then

        end
        if datapoint["type"] == "NyxFile" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy target NyxFile file ? ") then
                location = NSNode1638NyxElementLocation::getLocationByAllMeansOrNull(datapoint)
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
                if File.dirname(File.dirname(location)) == "/Users/pascal/Galaxy/DataBank/Catalyst/Asteroids-NyxDirectories" then
                    puts "Found NyxDirectory: #{location}"
                    parent = File.dirname(location)
                    puts "Going to remove the parent folder: #{parent}"
                    LucilleCore::removeFileSystemLocation(parent)
                else
                    # We are in the interesting case of an asteroid with a NyxHud child which is not in Asteroids-NyxDirectories
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
            return false if location.nil?
            FileUtils.rm(location)
        end

        NyxObjects2::destroy(datapoint)

        true
    end
end
