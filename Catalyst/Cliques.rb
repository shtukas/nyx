
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

require 'colorize'

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/A10495.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Multiverse.rb"

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

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

    # Cliques::makeA10495sInteractively()
    def self.makeA10495sInteractively()
        targets = []
        loop {
            target = A10495::issueNewTargetInteractivelyOrNull()
            break if target.nil?
            puts JSON.pretty_generate(target)
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
            "targets"           => Cliques::makeA10495sInteractively(),
            "tags"              => Cliques::makeTagsInteractively()
        }
        puts JSON.pretty_generate(clique)
        Cliques::save(clique)
        if shouldStarlightNodeInvite and LucilleCore::askQuestionAnswerAsBoolean("Would you like to add this clique to a Starlight node ? ") then
            node = Multiverse::selectTimelinePossiblyCreateOneOrNull()
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

    # Cliques::tags()
    def self.tags()
        Cliques::cliques()
            .map{|clique| clique["tags"] }
            .flatten
            .uniq
            .sort
    end

    # ------------------------------------------------------------

    # Cliques::visitTag(tag)
    def self.visitTag(tag)
        loop {
            system('clear')
            puts "Cliques: Tag Diving: #{tag}"
            items = []
            Cliques::cliques()
                .select{|clique| clique["tags"].map{|tag| tag.downcase }.include?(tag.downcase) }
                .each{|clique|
                    items << [ Cliques::cliqueToString(clique) , lambda { Cliques::visitClique(clique) } ]
                }
            break if items.empty?
            status = LucilleCore::menuItemsWithLambdas(items)
            break if !status
        }
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
            if LucilleCore::askQuestionAnswerAsBoolean("I could not find any target for this clique. Dive? ") then
                Cliques::visitClique(clique)
            end
            return
        end
        target = 
            if clique["targets"].size == 1 then
                clique["targets"].first
            else
                LucilleCore::selectEntityFromListOfEntitiesOrNull("target:", clique["targets"], lambda{|target| A10495::targetToString(target) })
            end
        if target.nil? then
            puts "No target was selected for this clique. Aborting opening."
            LucilleCore::pressEnterToContinue()
            return
        end
        puts JSON.pretty_generate(target)
        A10495::openTarget(target)
    end

    # Cliques::visitClique(clique)
    def self.visitClique(clique)
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
                "A10495 (add new)", 
                lambda{
                    target = A10495::issueNewTargetInteractivelyOrNull()
                    next if target.nil?
                    clique["targets"] << target
                    Cliques::save(clique)
                }]
            items << [
                "A10495 (select and remove)", 
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
                    node = Multiverse::selectTimelinePossiblyCreateOneOrNull()
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
                    items << ["[A10495] #{A10495::targetToString(target)}", lambda{ A10495Navigation::visit(target) }] 
                }

            TimelineOwnership::getTimelinesForEntity(clique)
                .sort{|n1, n2| n1["name"] <=> n2["name"] }
                .each{|timeline| items << ["[timeline] #{Timelines::timelineToString(timeline)}", lambda{ MultiverseNavigation::visit(timeline) }] }

            status = LucilleCore::menuItemsWithLambdas(items) # Boolean # Indicates whether an item was chosen
            break if !status
        }
    end

    # Cliques::visitGivenCliques(cliques)
    def self.visitGivenCliques(cliques)
        loop {
            clique = LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", cliques, lambda{|clique| Cliques::cliqueToString(clique) })
            break if clique.nil?
            Cliques::visitClique(clique)
        }
    end

    # Cliques::main()
    def self.main()
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
                    Cliques::visitClique(clique)
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
                Cliques::visitGivenCliques(cliques)
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

class CliquesSearch

    # CliquesSearch::searchPatternToTags(searchPattern)
    def self.searchPatternToTags(searchPattern)
        Cliques::tags()
            .select{|tag| tag.downcase.include?(searchPattern.downcase) }
    end

    # CliquesSearch::searchPatternToCliques(searchPattern)
    def self.searchPatternToCliques(searchPattern)
        Cliques::cliques()
            .select{|clique| clique["description"].downcase.include?(searchPattern.downcase) }
    end

    # CliquesSelection::selectSomethingOrNullPatternToCliquesDescriptions(searchPattern)
    def self.searchPatternToCliquesDescriptions(searchPattern)
        CliquesSearch::searchPatternToCliques(searchPattern)
            .map{|clique| clique["description"] }
            .uniq
            .sort
    end

    # CliquesSearch::search(fragment)
    # Objects returned by the function: they are essentially search results.
    # {
    #     "type" => "clique",
    #     "clique" => clique
    # }
    # {
    #     "type" => "tag",
    #     "tag" => tag
    # }
    def self.search(fragment)
        objs1 = CliquesSearch::searchPatternToCliques(fragment)
                    .map{|clique| 
                        {
                            "type" => "clique",
                            "clique" => clique
                        }
                    }
        objs2 = CliquesSearch::searchPatternToTags(fragment)
                    .map{|tag|
                        {
                            "type" => "tag",
                            "tag" => tag
                        }
                    }
        objs1 + objs2
    end

    # CliquesSearch::diveSearchResults(items)
    def self.diveSearchResults(items)
        loop {
            itemsObjectToMenuItemOrNull = lambda {|object|
                if object["type"] == "clique" then
                    clique = object["clique"]
                    return [ Cliques::cliqueToString(clique) , lambda { Cliques::visitClique(clique) } ]
                end
                if object["type"] == "tag" then
                    tag = object["tag"]
                    return [ "tag: #{tag}" , lambda { Cliques::visitTag(tag) } ]
                end
                nil
            }
            items2 = items
                        .map{|object| itemsObjectToMenuItemOrNull.call(object) }
                        .compact
            status = LucilleCore::menuItemsWithLambdas(items2)
            break if !status
        }
    end

    # CliquesSearch::searchAndVisit()
    def self.searchAndVisit()
        fragment = LucilleCore::askQuestionAnswerAsString("search and visit: fragment: ")
        return nil if fragment.nil?
        items = CliquesSearch::search(fragment)
        CliquesSearch::diveSearchResults(items)
    end
end

class CliquesNavigation

    # CliquesNavigation::generalNavigation()
    def self.generalNavigation()
        CliquesSearch::searchAndVisit()
    end

    # CliquesNavigation::visit(clique)
    def self.visit(clique)
        Cliques::visitClique(clique)
    end
end

class CliquesSelection

    # CliquesSelection::selectSomethingOrNull()
    def self.selectSomethingOrNull()
        puts "-> You are on a selection Quest [selecting a clique]".green
        LucilleCore::pressEnterToContinue()
        descriptionXp = lambda { |clique|
            "#{clique["description"]} (#{clique["uuid"][0,4]}) [#{clique["tags"].join(",")}]"
        }
        cliques = Cliques::cliques()
        descriptionsxp = cliques.reverse.map{|clique| descriptionXp.call(clique) }
        selectedDescriptionxp = CatalystCommon::chooseALinePecoStyle("select clique (empty for null)", [""] + descriptionsxp)
        return nil if selectedDescriptionxp == ""
        clique = cliques.select{|c| descriptionXp.call(c) == selectedDescriptionxp }.first
        return nil if clique.nil?
        return CliquesSelection::onASomethingSelectionQuest(clique)
    end

    # CliquesSelection::onASomethingSelectionQuest(clique)
    def self.onASomethingSelectionQuest(clique)
        loop {

            puts "-> You are on a selection Quest [visiting a clique]".green
            puts ""

            clique = Cliques::getOrNull(clique["uuid"]) # useful if we have modified it

            return nil if clique.nil? # useful if we have just destroyed it

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
                "A10495 (add new)", 
                lambda{
                    target = A10495::issueNewTargetInteractivelyOrNull()
                    next if target.nil?
                    clique["targets"] << target
                    Cliques::save(clique)
                }]
            items << [
                "A10495 (select and remove)", 
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
                    node = Multiverse::selectTimelinePossiblyCreateOneOrNull()
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
                        return nil
                    end
                }]
            clique["targets"]
                .each{|target| 
                    items << ["[A10495] #{A10495::targetToString(target)}", lambda{ 
                        A10495Selection::onASomethingSelectionQuest(target)
                    }] 
                }

            TimelineOwnership::getTimelinesForEntity(clique)
                .sort{|n1, n2| n1["name"] <=> n2["name"] }
                .each{|timeline| items << ["[timeline] #{Timelines::timelineToString(timeline)}", lambda{ 
                    something = MultiverseSelection::onASomethingSelectionQuest(timeline) 
                    if something then
                        KeyValueStore::set(nil, $GenericEntityQuestSelectionKey, JSON.generate(something))
                    end
                }] }

            items << [
                "return(this)", 
                lambda{
                    KeyValueStore::set(nil, $GenericEntityQuestSelectionKey, JSON.generate(clique))
                }]

            status = LucilleCore::menuItemsWithLambdas(items) # Boolean # Indicates whether an item was chosen
            
            break if KeyValueStore::getOrNull(nil, $GenericEntityQuestSelectionKey) # a selection has been made, either something from visiting a timeline or self.

            break if !status
        }

        if KeyValueStore::getOrNull(nil, $GenericEntityQuestSelectionKey) then
            return JSON.parse(KeyValueStore::getOrNull(nil, $GenericEntityQuestSelectionKey))
        end

        nil
    end
end
