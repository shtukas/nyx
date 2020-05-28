
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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/A10495.rb"

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

    # Cliques::makeA10495Interactively()
    def self.makeA10495Interactively()
        targets = []
        loop {
            target = A10495::issueNewTargetInteractivelyOrNull()
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
            "targets"           => Cliques::makeA10495Interactively(),
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

    # Cliques::printCliqueDetails(clique)
    def self.printCliqueDetails(clique)
        puts "Clique:"
        puts "    uuid: #{clique["uuid"]}"
        puts "    description: #{clique["description"].green}"
        puts ""

        puts "    targets:"
        clique["targets"]
            .each{|target|
                puts "        #{A10495::targetToString(target)}"
            }
        puts ""

        if clique["tags"].empty? then
            puts "    tags: (empty set)"
        else
            puts "    tags"
            clique["tags"].each{|item|
                puts "        #{item}"
            }
        end
        puts ""

        timelines = TimelineOwnership::getTimelinesForEntity(clique)
        if timelines.empty? then
            puts "    timelines: (empty set)"
        else
            puts "    timelines"
            timelines.each{|node|
                puts "        #{Timelines::timelineToString(node)}"
            }
        end
    end

    # Cliques::openClique(clique)
    def self.openClique(clique)
        Cliques::printCliqueDetails(clique)
        puts "    -> Opening..."
        if clique["targets"].size == 0 then
            if LucilleCore::askQuestionAnswerAsBoolean("I could not find target for this clique. Dive? ") then
                CliquesEvolved::navigateClique(clique)
            end
            return
        end
        target = nil
        if clique["targets"].size == 1 then
            target = clique["targets"].first
        else
            target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target:", clique["targets"], lambda{|target| A10495::targetToString(target) })
        end
        return if target.nil?
        puts JSON.pretty_generate(target)
        A10495::openTarget(target)
    end

    # Cliques::cliquesDive(cliques)
    def self.cliquesDive(cliques)
        loop {
            clique = LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", cliques, lambda{|clique| Cliques::cliqueToString(clique) })
            break if clique.nil?
            CliquesEvolved::navigateClique(clique)
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
                    .each{|clique|
                        uuid = clique["uuid"]
                        tags1 = clique["tags"]
                        tags2 = tags1.map{|tag| renameTagIfNeeded.call(tag, oldname, newname) }
                        if tags1.join(':') != tags2.join(':') then
                            clique["tags"] = tags2
                            Cliques::save(clique)
                        end
                    }
            end
            if operation == "clique dive (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                clique = Cliques::getOrNull(uuid)
                if clique then
                    CliquesEvolved::navigateClique(clique)
                else
                    puts "Could not find clique for uuid (#{uuid})"
                end
            end
            if operation == "repair json (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                clique = Cliques::getOrNull(uuid)
                if clique then
                    cliquejson = CatalystCommon::editTextUsingTextmate(JSON.pretty_generate(clique))
                    clique = JSON.parse(cliquejson)
                    Cliques::save(clique)
                else
                    puts "Could not find clique for uuid (#{uuid})"
                end
            end
            if operation == "make new clique" then
                Cliques::issueCliqueInteractivelyOrNull(true)
            end
            if operation == "show newly created cliques" then
                cliques = Cliques::cliques()
                            .sort{|p1, p2| p1["creationTimestamp"] <=> p2["creationTimestamp"] }
                            .reverse
                            .first(20)
                Cliques::cliquesDive(cliques)
            end
            if operation == "clique destroy (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                clique = Cliques::getOrNull(uuid)
                next if clique.nil?
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
            .map{|clique| clique["tags"] }
            .flatten
            .uniq
            .sort
    end

    # CliquesEvolved::selectCliqueOrNull(cliques)
    def self.selectCliqueOrNull(cliques)
        descriptionXp = lambda { |clique|
            "#{clique["description"]} (#{clique["uuid"][0,4]})"
        }
        descriptionsxp = cliques.map{|clique| descriptionXp.call(clique) }
        selectedDescriptionxp = CatalystCommon::chooseALinePecoStyle("select clique (empty for null)", [""] + descriptionsxp)
        return nil if selectedDescriptionxp == ""
        clique = cliques.select{|clique| descriptionXp.call(clique) == selectedDescriptionxp }.first
        return nil if clique.nil?
        clique
    end

    # CliquesEvolved::cliquesDive(cliques)
    def self.cliquesDive(cliques)
        loop {
            clique = CliquesEvolved::selectCliqueOrNull(cliques)
            break if clique.nil?
            CliquesEvolved::navigateClique(clique)
        }
    end

    # CliquesEvolved::tagDive(tag)
    def self.tagDive(tag)
        loop {
            system('clear')
            puts "Cliques Tag Diving: #{tag}"
            items = []
            Cliques::cliques()
                .select{|clique| clique["tags"].map{|tag| tag.downcase }.include?(tag.downcase) }
                .each{|clique|
                    items << [ clique["description"] , lambda { CliquesEvolved::navigateClique(clique) } ]
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
            .select{|clique| clique["description"].downcase.include?(searchPattern.downcase) }
    end

    # CliquesEvolved::searchDiveAndSelectPatternToCliquesDescriptions(searchPattern)
    def self.searchPatternToCliquesDescriptions(searchPattern)
        CliquesEvolved::searchPatternToCliques(searchPattern)
            .map{|clique| clique["description"] }
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
    #     "type" => "clique",
    #     "clique" => clique
    # }
    # {
    #     "type" => "tag",
    #     "tag" => tag
    # }
    def self.nextGenSearchFragmentToGlobalSearchStructure(fragment)
        objs1 = CliquesEvolved::searchPatternToCliques(fragment)
                    .map{|clique| 
                        {
                            "type" => "clique",
                            "clique" => clique
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
                if object["type"] == "clique" then
                    clique = object["clique"]
                    return [ "clique: #{clique["description"]}" , lambda { CliquesEvolved::navigateClique(clique) } ]
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

            Cliques::printCliqueDetails(clique)

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
                    clique["description"] = description
                    Cliques::save(clique)
                }]
            items << [
                "targets (add new)", 
                lambda{
                    target = A10495::issueNewTargetInteractivelyOrNull()
                    next if target.nil?
                    clique["targets"] << target
                    Cliques::save(clique)
                }]
            items << [
                "targets (select and remove)", 
                lambda{
                    toStringLambda = lambda { |target| A10495::targetToString(target) }
                    target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", clique["targets"], toStringLambda)
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
                "add to timeline", 
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
                    items << ["[catalyst A10495] #{A10495::targetToString(target)}", lambda{ A10495::targetDive(target)}] 
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
