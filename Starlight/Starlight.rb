
# encoding: UTF-8

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
        filepath = "#{StartlightNodes::pathToRepository()}/#{node["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(node)) }
    end

    # StartlightNodes::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{StartlightNodes::pathToRepository()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # StartlightNodes::nodes()
    def self.nodes()
        Dir.entries(StartlightNodes::pathToRepository())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{StartlightNodes::pathToRepository()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # StartlightNodes::makeNodeInteractivelyOrNull()
    def self.makeNodeInteractivelyOrNull()
        {
            "uuid" => SecureRandom.uuid,
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
end

class StartlightPaths

    # StartlightPaths::path()
    def self.path()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Starlight/paths"
    end

    # StartlightPaths::save(path)
    def self.save(path)
        filepath = "#{StartlightPaths::pathToRepository()}/#{path["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(path)) }
    end

    # StartlightPaths::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{StartlightPaths::pathToRepository()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # StartlightPaths::paths()
    def self.paths()
        Dir.entries(StartlightPaths::pathToRepository())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{StartlightPaths::pathToRepository()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # StartlightPaths::makePathInteractivelyOrNull()
    def self.makePathInteractivelyOrNull()
        {
            "uuid"        => SecureRandom.uuid,
            "sourceuuid"  => LucilleCore::askQuestionAnswerAsString("sourceuuid: ")
            "targetuuid"  => LucilleCore::askQuestionAnswerAsString("targetuuid: ")
        }
    end

    # ------------------------------------------------------------------------
    # User Interface

    # StartlightPaths::pathToString(path)
    def self.pathToString(path)
        "[starlight path] #{path["sourceuuid"]} -> #{path["targetuuid"]}"
    end
end

class StarlightDataClaim

    # StarlightDataClaim::dataclaim()
    def self.dataclaim()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Starlight/dataclaims"
    end

    # StarlightDataClaim::save(dataclaim)
    def self.save(dataclaim)
        filepath = "#{StarlightDataClaim::dataclaimToRepository()}/#{dataclaim["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(dataclaim)) }
    end

    # StarlightDataClaim::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{StarlightDataClaim::dataclaimToRepository()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # StarlightDataClaim::dataclaims()
    def self.dataclaims()
        Dir.entries(StarlightDataClaim::dataclaimToRepository())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{StarlightDataClaim::dataclaimToRepository()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # StarlightDataClaim::makePathInteractivelyOrNull()
    def self.makePathInteractivelyOrNull()
        {
            "uuid"       => SecureRandom.uuid,
            "nodeuuid"   => LucilleCore::askQuestionAnswerAsString("nodeuuid: ")
            "pointuuid"  => LucilleCore::askQuestionAnswerAsString("pointuuid: ")
        }
    end

    # ------------------------------------------------------------------------
    # User Interface

    # StarlightDataClaim::dataclaimToString(dataclaim)
    def self.dataclaimToString(dataclaim)
        "[starlight dataclaim] #{dataclaim["nodeuuid"]} -> #{dataclaim["pointuuid"]}"
    end
end

