
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"

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

# -----------------------------------------------------------------

class StartlightNodes

    # StartlightNodes::path()
    def self.path()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Starlight/nodes"
    end

    # StartlightNodes::save(node)
    def self.save(node)
        filepath = "#{StartlightNodes::path()}/#{node["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(node)) }
    end

    # StartlightNodes::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{StartlightNodes::path()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # StartlightNodes::nodes()
    def self.nodes()
        Dir.entries(StartlightNodes::path())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{StartlightNodes::path()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|i1, i2| i1["creationTimestamp"]<=>i2["creationTimestamp"] }
    end

    # StartlightNodes::makeNodeInteractivelyOrNull()
    def self.makeNodeInteractivelyOrNull()
        {
            "uuid" => SecureRandom.uuid,
            "creationTimestamp" => Time.new.to_f,
            "name" => LucilleCore::askQuestionAnswerAsString("nodename: ")
        }
    end

    # ------------------------------------------------------------------------
    # User Interface

    # StartlightNodes::nodeToString(node)
    def self.nodeToString(node)
        "[starlight node] #{node["name"]} (#{node["uuid"][0, 4]})"
    end

    # StartlightNodes::nodeDive(node)
    def self.nodeDive(node)
        loop {
            puts JSON.pretty_generate(node)
            operations = [
                "rename"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "rename" then
                node["description"] = CatalystCommon::editTextUsingTextmate(node["description"]).strip
                StartlightNodes::save(node)
            end
        }
    end

    # StartlightNodes::nodesDive()
    def self.nodesDive()
        puts "StartlightNodes::nodesDive() not implemented yet"
        LucilleCore::pressEnterToContinue()
    end

    # StartlightNodes::selectNodeOrNull()
    def self.selectNodeOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("node", StartlightNodes::nodes(), lambda {|node| StartlightNodes::nodeToString(node) })
    end
end

class StartlightPaths

    # StartlightPaths::path()
    def self.path()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Starlight/paths"
    end

    # StartlightPaths::save(path)
    def self.save(path)
        filepath = "#{StartlightPaths::path()}/#{path["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(path)) }
    end

    # StartlightPaths::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{StartlightPaths::path()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # StartlightPaths::paths()
    def self.paths()
        Dir.entries(StartlightPaths::path())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{StartlightPaths::path()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|i1, i2| i1["creationTimestamp"]<=>i2["creationTimestamp"] }
    end

    # StartlightPaths::makePathInteractivelyOrNull()
    def self.makePathInteractivelyOrNull()
        {
            "uuid"        => SecureRandom.uuid,
            "creationTimestamp" => Time.new.to_f,
            "sourceuuid"  => LucilleCore::askQuestionAnswerAsString("sourceuuid: "),
            "targetuuid"  => LucilleCore::askQuestionAnswerAsString("targetuuid: ")
        }
    end

    # StartlightPaths::makePathFromNodes(node1, node2)
    def self.makePathFromNodes(node1, node2)
        {
            "uuid"        => SecureRandom.uuid,
            "creationTimestamp" => Time.new.to_f,
            "sourceuuid"  => node1["uuid"],
            "targetuuid"  => node2["uuid"]
        }
    end

    # ------------------------------------------------------------------------
    # User Interface

    # StartlightPaths::pathToString(path)
    def self.pathToString(path)
        "[starlight path] #{path["sourceuuid"]} -> #{path["targetuuid"]}"
    end
end

class StarlightDataClaims

    # StarlightDataClaims::path()
    def self.path()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Starlight/dataclaims"
    end

    # StarlightDataClaims::save(dataclaim)
    def self.save(dataclaim)
        filepath = "#{StarlightDataClaims::path()}/#{dataclaim["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(dataclaim)) }
    end

    # StarlightDataClaims::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{StarlightDataClaims::path()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # StarlightDataClaims::dataclaims()
    def self.dataclaims()
        Dir.entries(StarlightDataClaims::path())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{StarlightDataClaims::path()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|i1, i2| i1["creationTimestamp"]<=>i2["creationTimestamp"] }
    end

    # StarlightDataClaims::makeClaimInteractivelyOrNull()
    def self.makeDataClaimInteractivelyOrNull()
        {
            "uuid"       => SecureRandom.uuid,
            "creationTimestamp" => Time.new.to_f,
            "nodeuuid"   => LucilleCore::askQuestionAnswerAsString("nodeuuid: "),
            "pointuuid"  => LucilleCore::askQuestionAnswerAsString("pointuuid: ")
        }
    end

    # StarlightDataClaims::makeClaimGivenNodeAndDataPoint(node, datapoint)
    def self.makeClaimGivenNodeAndDataPoint(node, datapoint)
        {
            "uuid"       => SecureRandom.uuid,
            "creationTimestamp" => Time.new.to_f,
            "nodeuuid"   => node["uuid"],
            "pointuuid"  => datapoint["uuid"]
        }
    end

    # ------------------------------------------------------------------------
    # User Interface

    # StarlightDataClaims::dataclaimToString(dataclaim)
    def self.dataclaimToString(dataclaim)
        "[starlight dataclaim] #{dataclaim["nodeuuid"]} -> #{dataclaim["pointuuid"]}"
    end
end

class StarlightX

    # StarlightX::userInterface()
    def self.userInterface()
        system("clear")
        loop {
            puts "Data 🗺️"
            operations = [
                "make starlight node",
                "make starlight path"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "make starlight node" then
                node = StartlightNodes::makeNodeInteractivelyOrNull()
                puts JSON.pretty_generate(node)
                StartlightNodes::save(node)
            end
            if operation == "make starlight path" then
                node1 = StartlightNodes::selectNodeOrNull()
                next if node1.nil?
                node2 = StartlightNodes::selectNodeOrNull()
                next if node2.nil?
                path = StartlightPaths::makePathFromNodes(node1, node2)
                puts JSON.pretty_generate(path)
                StartlightPaths::save(path)
            end
        }
    end
end

