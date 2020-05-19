
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataPoints.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CatalystStandardTargets.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"

# -----------------------------------------------------------------

class DataPoints

    # DataPoints::pathToRepository()
    def self.pathToRepository()
        "/Users/pascal/Galaxy/DataBank/Catalyst/DataPoints"
    end

    # DataPoints::fsckDataPointExplode(datapoint)
    def self.fsckDataPointExplode(datapoint)
        raise "DataPoints::fsckDataPointExplode [uuid] {#{datapoint}}" if datapoint["uuid"].nil?
        raise "DataPoints::fsckDataPointExplode [creationTimestamp] {#{datapoint}}" if datapoint["creationTimestamp"].nil?
        raise "DataPoints::fsckDataPointExplode [description] {#{datapoint}}" if datapoint["description"].nil?
        raise "DataPoints::fsckDataPointExplode [targets] {#{datapoint}}" if datapoint["targets"].nil?
        raise "DataPoints::fsckDataPointExplode [tags] {#{datapoint}}" if datapoint["tags"].nil?
    end

    # DataPoints::save(datapoint)
    def self.save(datapoint)
        DataPoints::fsckDataPointExplode(datapoint)
        filepath = "#{DataPoints::pathToRepository()}/#{datapoint["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(datapoint)) }
    end

    # DataPoints::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{DataPoints::pathToRepository()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # DataPoints::destroy(uuid)
    def self.destroy(uuid)
        filepath = "#{DataPoints::pathToRepository()}/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # DataPoints::datapoints()
    def self.datapoints()
        Dir.entries(DataPoints::pathToRepository())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{DataPoints::pathToRepository()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # DataPoints::makeCatalystStandardTargetsInteractively()
    def self.makeCatalystStandardTargetsInteractively()
        targets = []
        loop {
            target = CatalystStandardTargets::makeNewTargetInteractivelyOrNull()
            break if target.nil?
            targets << target
        }
        targets
    end

    # DataPoints::makeTagsInteractively()
    def self.makeTagsInteractively()
        tags = []
        loop {
            tag = LucilleCore::askQuestionAnswerAsString("tag (empty to exit): ")
            break if tag == ""
            tags << tag
        }
        tags
    end

    # DataPoints::issueDataPointInteractivelyOrNull()
    def self.issueDataPointInteractivelyOrNull()
        datapoint = {
            "uuid"              => SecureRandom.uuid,
            "creationTimestamp" => Time.new.to_f,
            "description"       => LucilleCore::askQuestionAnswerAsString("description: "),
            "targets"           => DataPoints::makeCatalystStandardTargetsInteractively(),
            "tags"              => DataPoints::makeTagsInteractively()
        }
        puts JSON.pretty_generate(datapoint)
        DataPoints::save(datapoint)
        if LucilleCore::askQuestionAnswerAsBoolean("Would you like to add this datapoint to a Starlight node ? ") then
            xnode = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", StartlightNodes::nodes(), lambda {|node| StartlightNodes::nodeToString(node) })
            if xnode then
                StarlightDataClaims::makeClaimGivenNodeAndDataPoint(xnode, datapoint)
            end
        end
        datapoint
    end

    # DataPoints::getDataPointsByTag(tag)
    def self.getDataPointsByTag(tag)
        DataPoints::datapoints()
            .select{|datapoint| datapoint["tags"].include?(tag) }
    end

    # ------------------------------------------------------------------------
    # User Interface

    # DataPoints::selectDataPointFromGivenSetOfDataPointsOrNull(datapoints)
    def self.selectDataPointFromGivenSetOfDataPointsOrNull(datapoints)
        return nil if datapoints.empty?
        LucilleCore::selectEntityFromListOfEntitiesOrNull("datapoint", datapoints, lambda { |datapoint| DataPoints::datapointToString(datapoint) })
    end

    # DataPoints::selectDataPointFromGivenSetOfDatPointsOrMakeANewOneOrNull(datapoints)
    def self.selectDataPointFromGivenSetOfDatPointsOrMakeANewOneOrNull(datapoints)
        datapoint = DataPoints::selectDataPointFromGivenSetOfDataPointsOrNull(datapoints)
        return datapoint if datapoint
        DataPoints::issueDataPointInteractivelyOrNull()
    end

    # DataPoints::datapointToString(datapoint)
    def self.datapointToString(datapoint)
        "datapoint #{datapoint["description"]} (#{datapoint["targets"].size}) [#{datapoint["uuid"][0, 4]}]"
    end

    # DataPoints::printPointDetails(uuid)
    def self.printPointDetails(point)
        puts "DataPoint:"
        puts "    uuid: #{point["uuid"]}"
        puts "    description: #{point["description"].green}"
        puts ""

        puts "    targets:"
        point["targets"]
            .each{|target|
                puts "        #{CatalystStandardTargets::targetToString(target)}"
            }
        puts ""

        if point["tags"].empty? then
            puts "    tags: (empty set)"
        else
            puts "    tags"
            point["tags"].each{|item|
                puts "        #{item}"
            }
        end
        puts ""

        starlightnodes = StarlightDataClaims::getNodesForDataPoint(point)
        if starlightnodes.empty? then
            puts "    starlightnodes: (empty set)"
        else
            puts "    starlightnodes"
            starlightnodes.each{|node|
                puts "        #{StartlightNodes::nodeToString(node)}"
            }
        end
    end

    # DataPoints::openPoint(point)
    def self.openPoint(point)
        DataPoints::printPointDetails(point)
        puts "    -> Opening..."
        if point["targets"].size == 0 then
            if LucilleCore::askQuestionAnswerAsBoolean("I could not find target for this datapoint. Dive? ") then
                DataPoints::pointDive(point)
            end
            return
        end
        target = nil
        if point["targets"].size == 1 then
            target = point["targets"].first
        else
            target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target:", point["targets"], lambda{|target| CatalystStandardTargets::targetToString(target) })
        end
        return if target.nil?
        puts JSON.pretty_generate(target)
        CatalystStandardTargets::openTarget(target)
    end

    # DataPoints::pointDive(point)
    def self.pointDive(point)
        loop {
            system("clear")
            DataPoints::printPointDetails(point)
            puts ""
            operations = [
                "open",
                "target(s) dive",
                nil,
                "edit description",
                "targets (add new)",
                "targets (select and remove)",
                "tags (add new)",
                "tags (remove)",
                nil,
                "add to starlight node",
                nil,
                "destroy datapoint"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "open" then
                DataPoints::openPoint(point)
            end
            if operation == "edit description" then
                description = CatalystCommon::editTextUsingTextmate(point["description"]).strip
                if description == "" or description.lines.to_a.size != 1 then
                    puts "Descriptions should be one non empty line"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                point["description"] = description
                DataPoints::save(point)
            end
            if operation == "target(s) dive" then
                if point["targets"].size == 1 then
                    CatalystStandardTargets::targetDive(point["targets"][0])
                else
                    CatalystStandardTargets::targetsDive(point["targets"])
                end
            end
            if operation == "targets (add new)" then
                target = CatalystStandardTargets::makeNewTargetInteractivelyOrNull()
                next if target.nil?
                point["targets"] << target
                DataPoints::save(point)
            end
            if operation == "targets (select and remove)" then
                toStringLambda = lambda { |target| CatalystStandardTargets::targetToString(target) }
                target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", point["targets"], toStringLambda)
                next if target.nil?
                point["targets"] = point["targets"].reject{|t| t["uuid"] == target["uuid"] }
                DataPoints::save(point)
            end
            if operation == "tags (add new)" then
                point["tags"] << LucilleCore::askQuestionAnswerAsString("tag: ")
                DataPoints::save(point)
            end
            if operation == "tags (remove)" then
                tag = LucilleCore::selectEntityFromListOfEntitiesOrNull("tag", point["tags"])
                next if tag.nil?
                point["tags"] = point["tags"].reject{|t| t == tag }
                DataPoints::save(point)
            end
            if operation == "add to starlight node" then
                node = StartlightNodes::selectNodePossiblyMakeANewOneOrNull()
                next if node.nil?
                dataclaim = StarlightDataClaims::makeClaimGivenNodeAndDataPoint(node, point)
                StarlightDataClaims::save(dataclaim)
            end
            if operation == "destroy datapoint" then
                if LucilleCore::askQuestionAnswerAsBoolean("Sure you want to get rid of that thing ? ") then
                    DataPoints::destroy(point["uuid"])
                    return
                end
            end
        }
    end

    # DataPoints::pointsDive(points)
    def self.pointsDive(points)
        loop {
            point = LucilleCore::selectEntityFromListOfEntitiesOrNull("datapoint", points, lambda{|point| DataPoints::datapointToString(point) })
            break if point.nil?
            DataPoints::pointDive(point)
        }
    end

    # DataPoints::userInterface()
    def self.userInterface()
        loop {
            system("clear")
            puts "DataPoints"
            operations = [
                "show newly created datapoints",
                "datapoint dive (uuid)",

                nil,
                "make new datapoint",

                nil,
                "rename tag",

                nil,
                "repair json (uuid)",
                "datapoint destroy (uuid)",
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "rename tag" then
                oldname = LucilleCore::askQuestionAnswerAsString("old name (capilisation doesn't matter): ")
                next if oldname.size == 0
                newname = LucilleCore::askQuestionAnswerAsString("new name: ")
                next if newname.size == 0
                renameTagIfNeeded = lambda {|tag, oldname, newname|
                    if tag.downcase == oldname.downcase then
                        tag = newname
                    end
                    tag
                }
                DataPoints::datapoints()
                    .each{|point|
                        uuid = point["uuid"]
                        tags1 = point["tags"]
                        tags2 = tags1.map{|tag| renameTagIfNeeded.call(tag, oldname, newname) }
                        if tags1.join(':') != tags2.join(':') then
                            point["tags"] = tags2
                            DataPoints::save(point)
                        end
                    }
            end
            if operation == "datapoint dive (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                point = DataPoints::getOrNull(uuid)
                if point then
                    DataPoints::pointDive(point)
                else
                    puts "Could not find datapoint for uuid (#{uuid})"
                end
            end
            if operation == "repair json (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                point = DataPoints::getOrNull(uuid)
                if point then
                    pointjson = CatalystCommon::editTextUsingTextmate(JSON.pretty_generate(point))
                    point = JSON.parse(pointjson)
                    DataPoints::save(point)
                else
                    puts "Could not find datapoint for uuid (#{uuid})"
                end
            end
            if operation == "make new datapoint" then
                DataPoints::issueDataPointInteractivelyOrNull()
            end
            if operation == "show newly created datapoints" then
                points = DataPoints::datapoints()
                            .sort{|p1, p2| p1["creationTimestamp"] <=> p2["creationTimestamp"] }
                            .reverse
                            .first(20)
                DataPoints::pointsDive(points)
            end
            if operation == "datapoint destroy (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                point = DataPoints::getOrNull(uuid)
                next if point.nil?
                if LucilleCore::askQuestionAnswerAsBoolean("Sure you want to get rid of that thing ? ") then
                    puts "Well, this operation has not been implemented yet"
                    LucilleCore::pressEnterToContinue()
                    return
                end
            end
        }
    end

end
