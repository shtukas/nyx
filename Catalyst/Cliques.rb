
# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Cliques.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Multiverse.rb"

# -----------------------------------------------------------------

class Cliques

    # Cliques::pathToRepository()
    def self.pathToRepository()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Cliques"
    end

    # Cliques::fsckExplodeIfFail(clique)
    def self.fsckExplodeIfFail(clique)
        raise "Cliques::fsckExplodeIfFail [uuid] {#{clique}}" if clique["uuid"].nil?
        raise "Cliques::fsckExplodeIfFail [creationTimestamp] {#{clique}}" if clique["creationTimestamp"].nil?
        raise "Cliques::fsckExplodeIfFail [description] {#{clique}}" if clique["description"].nil?
        raise "Cliques::fsckExplodeIfFail [targets] {#{clique}}" if clique["targets"].nil?
        raise "Cliques::fsckExplodeIfFail [tags] {#{clique}}" if clique["tags"].nil?
    end

    # Cliques::save(clique)
    def self.save(clique)
        Cliques::fsckExplodeIfFail(clique)
        filepath = "#{Cliques::pathToRepository()}/#{clique["uuid"]}.json"
        File.open(filepath, "w") {|f| f.puts(JSON.pretty_generate(clique)) }
    end

    # Cliques::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{Cliques::pathToRepository()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Cliques::destroy(uuid)
    def self.destroy(uuid)
        filepath = "#{Cliques::pathToRepository()}/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # Cliques::cliques()
    # cliques are given in the increasing creation order.
    def self.cliques()
        Dir.entries(Cliques::pathToRepository())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{Cliques::pathToRepository()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|i1, i2| i1["creationTimestamp"]<=>i2["creationTimestamp"] }
    end

    # Cliques::makeCatalystStandardTargetsInteractively()
    def self.makeCatalystStandardTargetsInteractively()
        targets = []
        loop {
            target = CatalystStandardTargets::issueNewTargetInteractivelyOrNull()
            break if target.nil?
            targets << target
        }
        targets
    end

    # Cliques::makeTagsInteractively()
    def self.makeTagsInteractively()
        tags = []
        loop {
            tag = LucilleCore::askQuestionAnswerAsString("tag (empty to exit): ")
            break if tag == ""
            tags << tag
        }
        tags
    end

    # Cliques::issueCliqueInteractivelyOrNull(shouldStarlightNodeInvite)
    def self.issueCliqueInteractivelyOrNull(shouldStarlightNodeInvite)
        clique = {
            "catalystType"      => "catalyst-type:clique",
            "creationTimestamp" => Time.new.to_f,
            "uuid"              => SecureRandom.uuid,

            "description"       => LucilleCore::askQuestionAnswerAsString("description: "),
            "targets"           => Cliques::makeCatalystStandardTargetsInteractively(),
            "tags"              => Cliques::makeTagsInteractively()
        }
        puts JSON.pretty_generate(clique)
        Cliques::save(clique)
        if shouldStarlightNodeInvite and LucilleCore::askQuestionAnswerAsBoolean("Would you like to add this clique to a Starlight node ? ") then
            node = Multiverse::selectOrNull()
            if node then
                TimelineOwnership::issueClaimGivenTimelineAndEntity(node, clique)
            end
        end
        clique
    end

    # Cliques::getCliquesByTag(tag)
    def self.getCliquesByTag(tag)
        Cliques::cliques()
            .select{|clique| clique["tags"].include?(tag) }
    end

    # Cliques::cliqueToString(clique)
    def self.cliqueToString(clique)
        "[clique] #{clique["description"]} [#{clique["uuid"][0, 4]}] (#{clique["targets"].size})"
    end

    # Cliques::printCliqueDetails(uuid)
    def self.printCliqueDetails(point)
        puts "Clique:"
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

        timelines = TimelineOwnership::getTimelinesForEntity(point)
        if timelines.empty? then
            puts "    timelines: (empty set)"
        else
            puts "    timelines"
            timelines.each{|node|
                puts "        #{Timelines::timelineToString(node)}"
            }
        end
    end

    # Cliques::openClique(point)
    def self.openClique(point)
        Cliques::printCliqueDetails(point)
        puts "    -> Opening..."
        if point["targets"].size == 0 then
            if LucilleCore::askQuestionAnswerAsBoolean("I could not find target for this clique. Dive? ") then
                CliquesEvolved::navigateClique(point)
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

    # Cliques::cliquesDive(points)
    def self.cliquesDive(points)
        loop {
            point = LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", points, lambda{|point| Cliques::cliqueToString(point) })
            break if point.nil?
            CliquesEvolved::navigateClique(point)
        }
    end

    # Cliques::userInterface()
    def self.userInterface()
        loop {
            system("clear")
            puts "Cliques"
            operations = [
                "show newly created cliques",
                "clique dive (uuid)",
                "make new clique",
                "rename tag",
                "repair json (uuid)",
                "clique destroy (uuid)",
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
                Cliques::cliques()
                    .each{|point|
                        uuid = point["uuid"]
                        tags1 = point["tags"]
                        tags2 = tags1.map{|tag| renameTagIfNeeded.call(tag, oldname, newname) }
                        if tags1.join(':') != tags2.join(':') then
                            point["tags"] = tags2
                            Cliques::save(point)
                        end
                    }
            end
            if operation == "clique dive (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                point = Cliques::getOrNull(uuid)
                if point then
                    CliquesEvolved::navigateClique(point)
                else
                    puts "Could not find clique for uuid (#{uuid})"
                end
            end
            if operation == "repair json (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                point = Cliques::getOrNull(uuid)
                if point then
                    pointjson = CatalystCommon::editTextUsingTextmate(JSON.pretty_generate(point))
                    point = JSON.parse(pointjson)
                    Cliques::save(point)
                else
                    puts "Could not find clique for uuid (#{uuid})"
                end
            end
            if operation == "make new clique" then
                Cliques::issueCliqueInteractivelyOrNull(true)
            end
            if operation == "show newly created cliques" then
                points = Cliques::cliques()
                            .sort{|p1, p2| p1["creationTimestamp"] <=> p2["creationTimestamp"] }
                            .reverse
                            .first(20)
                Cliques::cliquesDive(points)
            end
            if operation == "clique destroy (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                point = Cliques::getOrNull(uuid)
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

class CliquesEvolved

    # CliquesEvolved::tags()
    def self.tags()
        Cliques::cliques()
            .map{|point| point["tags"] }
            .flatten
            .uniq
            .sort
    end

    # CliquesEvolved::selectCliqueOrNull(points)
    def self.selectCliqueOrNull(points)
        descriptionXp = lambda { |point|
            "#{point["description"]} (#{point["uuid"][0,4]})"
        }
        descriptionsxp = points.map{|point| descriptionXp.call(point) }
        selectedDescriptionxp = CatalystCommon::chooseALinePecoStyle("select clique (empty for null)", [""] + descriptionsxp)
        return nil if selectedDescriptionxp == ""
        point = points.select{|point| descriptionXp.call(point) == selectedDescriptionxp }.first
        return nil if point.nil?
        point
    end

    # CliquesEvolved::cliquesDive(points)
    def self.cliquesDive(points)
        loop {
            point = CliquesEvolved::selectCliqueOrNull(points)
            break if point.nil?
            CliquesEvolved::navigateClique(point)
        }
    end

    # CliquesEvolved::tagDive(tag)
    def self.tagDive(tag)
        loop {
            system('clear')
            puts "Data Points Tag Diving: #{tag}"
            items = []
            Cliques::cliques()
                .select{|point| point["tags"].map{|tag| tag.downcase }.include?(tag.downcase) }
                .each{|point|
                    items << [ point["description"] , lambda { CliquesEvolved::navigateClique(point) } ]
                }
            break if items.empty?
            status = LucilleCore::menuItemsWithLambdas(items)
            break if !status
        }
    end

    # CliquesEvolved::searchPatternToTags(searchPattern)
    def self.searchPatternToTags(searchPattern)
        CliquesEvolved::tags()
            .select{|tag| tag.downcase.include?(searchPattern.downcase) }
    end

    # CliquesEvolved::searchPatternToCliques(searchPattern)
    def self.searchPatternToCliques(searchPattern)
        Cliques::cliques()
            .select{|point| point["description"].downcase.include?(searchPattern.downcase) }
    end

    # CliquesEvolved::searchDiveAndSelectPatternToCliquesDescriptions(searchPattern)
    def self.searchPatternToCliquesDescriptions(searchPattern)
        CliquesEvolved::searchPatternToCliques(searchPattern)
            .map{|point| point["description"] }
            .uniq
            .sort
    end

    # CliquesEvolved::nextGenGetSearchFragmentOrNull()
    def self.nextGenGetSearchFragmentOrNull() # () -> String
        LucilleCore::askQuestionAnswerAsString("search fragment: ")
    end

    # CliquesEvolved::nextGenSearchFragmentToGlobalSearchStructure(fragment)
    # Objects returned by the function: they are essentially search results.
    # {
    #     "type" => "point",
    #     "point" => point
    # }
    # {
    #     "type" => "tag",
    #     "tag" => tag
    # }
    def self.nextGenSearchFragmentToGlobalSearchStructure(fragment)
        objs1 = CliquesEvolved::searchPatternToCliques(fragment)
                    .map{|point| 
                        {
                            "type" => "point",
                            "point" => point
                        }
                    }
        objs2 = CliquesEvolved::searchPatternToTags(fragment)
                    .map{|tag|
                        {
                            "type" => "tag",
                            "tag" => tag
                        }
                    }
        objs1 + objs2
    end

    # CliquesEvolved::globalSearchStructureDive(globalss)
    def self.globalSearchStructureDive(globalss)
        loop {
            globalssObjectToMenuItemOrNull = lambda {|object|
                if object["type"] == "point" then
                    point = object["point"]
                    return [ "clique: #{point["description"]}" , lambda { CliquesEvolved::navigateClique(point) } ]
                end
                if object["type"] == "tag" then
                    tag = object["tag"]
                    return [ "tag: #{tag}" , lambda { CliquesEvolved::tagDive(tag) } ]
                end
                nil
            }
            items = globalss
                .map{|object| globalssObjectToMenuItemOrNull.call(object) }
                .compact
            status = LucilleCore::menuItemsWithLambdas(items)
            break if !status
        }
    end

    # CliquesEvolved::navigateClique(clique)
    def self.navigateClique(clique)
        loop {
            puts ""
            clique = Cliques::getOrNull(clique["uuid"]) # useful if we have modified it
            return if clique.nil? # useful if we have just destroyed it

            items = []

            items << ["open", lambda{  Cliques::openClique(clique) }]
            items << [
                "edit description", 
                lambda{
                    description = CatalystCommon::editTextUsingTextmate(clique["description"]).strip
                    if description == "" or description.lines.to_a.size != 1 then
                        puts "Descriptions should be one non empty line"
                        LucilleCore::pressEnterToContinue()
                        return
                    end
                    point["description"] = description
                    Cliques::save(clique)
                }]
            items << [
                "targets (add new)", 
                lambda{
                    target = CatalystStandardTargets::issueNewTargetInteractivelyOrNull()
                    next if target.nil?
                    clique["targets"] << target
                    Cliques::save(clique)
                }]
            items << [
                "targets (select and remove)", 
                lambda{
                    toStringLambda = lambda { |target| CatalystStandardTargets::targetToString(target) }
                    target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", point["targets"], toStringLambda)
                    next if target.nil?
                    clique["targets"] = clique["targets"].reject{|t| t["uuid"] == target["uuid"] }
                    Cliques::save(clique)
                }]
            items << [
                "tags (add new)", 
                lambda{
                    clique["tags"] << LucilleCore::askQuestionAnswerAsString("tag: ")
                    Cliques::save(clique)
                }]
            items << [
                "tags (remove)", 
                lambda{
                    tag = LucilleCore::selectEntityFromListOfEntitiesOrNull("tag", clique["tags"])
                    next if tag.nil?
                    clique["tags"] = clique["tags"].reject{|t| t == tag }
                    Cliques::save(clique)
                }]
            items << [
                "add to starlight node", 
                lambda{
                    node = Multiverse::selectOrNull()
                    next if node.nil?
                    TimelineOwnership::issueClaimGivenTimelineAndEntity(node, clique)
                }]
            items << [
                "register as open cycle", 
                lambda{
                    claim = {
                        "uuid"              => SecureRandom.uuid,
                        "creationTimestamp" => Time.new.to_f,
                        "entityuuid"        => clique["uuid"],
                    }
                    puts JSON.pretty_generate(claim)
                    File.open("/Users/pascal/Galaxy/DataBank/Catalyst/OpenCycles/#{claim["uuid"]}.json", "w"){|f| f.puts(JSON.pretty_generate(claim)) }
                }]
            items << [
                "destroy clique", 
                lambda{
                    if LucilleCore::askQuestionAnswerAsBoolean("Sure you want to get rid of that thing ? ") then
                        Cliques::destroy(clique["uuid"])
                        return
                    end
                }]
            clique["targets"]
                .each{|target| 
                    items << ["[catalyst standard target] #{CatalystStandardTargets::targetToString(target)}", lambda{ CatalystStandardTargets::targetDive(target)}] 
                }

            TimelineOwnership::getTimelinesForEntity(clique)
                .sort{|n1, n2| n1["name"] <=> n2["name"] }
                .each{|n| items << ["[node owner] #{Timelines::timelineToString(n)}", lambda{ Multiverse::visitTimeline(n) }] }
            items << ["select", lambda{ $EvolutionsFindXSingleton = clique }]
            status = LucilleCore::menuItemsWithLambdas(items) # Boolean # Indicates whether an item was chosen
            break if !status
        }
    end

    # CliquesEvolved::searchDiveAndSelect()
    def self.searchDiveAndSelect()
        fragment = CliquesEvolved::nextGenGetSearchFragmentOrNull()
        return nil if fragment.nil?
        globalss = CliquesEvolved::nextGenSearchFragmentToGlobalSearchStructure(fragment)
        CliquesEvolved::globalSearchStructureDive(globalss)
        return $EvolutionsFindXSingleton
    end

    # CliquesEvolved::navigate()
    def self.navigate()
        fragment = CliquesEvolved::nextGenGetSearchFragmentOrNull()
        return nil if fragment.nil?
        globalss = CliquesEvolved::nextGenSearchFragmentToGlobalSearchStructure(fragment)
        CliquesEvolved::globalSearchStructureDive(globalss)
    end
end
