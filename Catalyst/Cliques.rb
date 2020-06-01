
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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"

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

    # Cliques::issue1CliqueInteractivelyOrNull()
    def self.issue1CliqueInteractivelyOrNull()
        clique = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "clique-933c2260-92d1-4578-9aaf-cd6557c664c6",
            "creationUnixtime" => Time.new.to_f,

            "description"      => LucilleCore::askQuestionAnswerAsString("description: "),
            "targets"          => Cliques::makeA10495sInteractively(),
            "tags"             => Cliques::makeTagsInteractively()
        }
        puts JSON.pretty_generate(clique)
        NyxObjects::commitToDisk(clique)
        clique
    end

    # Cliques::issueCliqueInteractivelyOrNull(canStarlightNodeInvite)
    def self.issueCliqueInteractivelyOrNull(canStarlightNodeInvite)
        clique = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "clique-933c2260-92d1-4578-9aaf-cd6557c664c6",
            "creationUnixtime" => Time.new.to_f,

            "description"      => LucilleCore::askQuestionAnswerAsString("description: "),
            "targets"          => Cliques::makeA10495sInteractively(),
            "tags"             => Cliques::makeTagsInteractively()
        }
        puts JSON.pretty_generate(clique)
        NyxObjects::commitToDisk(clique)
        if canStarlightNodeInvite and LucilleCore::askQuestionAnswerAsBoolean("Would you like to add this clique to a Starlight node ? ") then
            node = StarlightUserInterface::selectNodeFromExistingOrCreateOneOrNull()
            if node then
                StarlightContents::issueClaimGivenNodeAndEntity(node, clique)
            end
        end
        clique
    end

    # Cliques::getCliquesByTag(tag)
    def self.getCliquesByTag(tag)
        NyxObjects::getObjects("clique-933c2260-92d1-4578-9aaf-cd6557c664c6")
            .select{|clique| clique["tags"].include?(tag) }
    end

    # Cliques::tags()
    def self.tags()
        NyxObjects::getObjects("clique-933c2260-92d1-4578-9aaf-cd6557c664c6")
            .map{|clique| clique["tags"] }
            .flatten
            .uniq
            .sort
    end

    # ------------------------------------------------------------

    # Cliques::selectCliqueFromExistingOrNull()
    def self.selectCliqueFromExistingOrNull()
        descriptionXp = lambda { |clique|
            "#{clique["description"]} (#{clique["uuid"][0,4]}) [#{clique["tags"].join(",")}]"
        }
        cliques = NyxObjects::getObjects("clique-933c2260-92d1-4578-9aaf-cd6557c664c6")
        descriptionsxp = cliques.reverse.map{|clique| descriptionXp.call(clique) }
        selectedDescriptionxp = CatalystCommon::chooseALinePecoStyle("select clique (empty for null)", [""] + descriptionsxp)
        return nil if selectedDescriptionxp == ""
        cliques.select{|c| descriptionXp.call(c) == selectedDescriptionxp }.first
    end

    # Cliques::visitTag(tag)
    def self.visitTag(tag)
        loop {
            system('clear')
            puts "Cliques: Tag Diving: #{tag}"
            items = []
            NyxObjects::getObjects("clique-933c2260-92d1-4578-9aaf-cd6557c664c6")
                .select{|clique| clique["tags"].map{|tag| tag.downcase }.include?(tag.downcase) }
                .each{|clique|
                    items << [ Cliques::cliqueToString(clique) , lambda { Cliques::cliqueDive(clique) } ]
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
        puts "    description: #{clique["description"]}"
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

        nodes = StarlightContents::getNodesForEntity(clique)
        if nodes.empty? then
            puts "    nodes: (empty set)"
        else
            puts "    nodes"
            nodes.each{|node|
                puts "        #{StarlightNodes::nodeToString(node)}"
            }
        end
    end

    # Cliques::openClique(clique)
    def self.openClique(clique)
        Cliques::printCliqueDetails(clique)
        puts "    -> Opening..."
        if clique["targets"].size == 0 then
            if LucilleCore::askQuestionAnswerAsBoolean("I could not find any target for this clique. Dive? ") then
                Cliques::cliqueDive(clique)
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

    # Cliques::cliqueDive(clique)
    def self.cliqueDive(clique)
        loop {
            puts ""
            clique = NyxObjects::getOrNull(clique["uuid"]) # useful if we have modified it
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
                    NyxObjects::commitToDisk(clique)
                }]
            items << [
                "A10495 (add new)", 
                lambda{
                    target = A10495::issueNewTargetInteractivelyOrNull()
                    next if target.nil?
                    clique["targets"] << target
                    NyxObjects::commitToDisk(clique)
                }]
            items << [
                "A10495 (select and remove)", 
                lambda{
                    toStringLambda = lambda { |target| A10495::targetToString(target) }
                    target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", clique["targets"], toStringLambda)
                    next if target.nil?
                    clique["targets"] = clique["targets"].reject{|t| t["uuid"] == target["uuid"] }
                    NyxObjects::commitToDisk(clique)
                }]
            items << [
                "tags (add new)", 
                lambda{
                    clique["tags"] << LucilleCore::askQuestionAnswerAsString("tag: ")
                    NyxObjects::commitToDisk(clique)
                }]
            items << [
                "tags (remove)", 
                lambda{
                    tag = LucilleCore::selectEntityFromListOfEntitiesOrNull("tag", clique["tags"])
                    next if tag.nil?
                    clique["tags"] = clique["tags"].reject{|t| t == tag }
                    NyxObjects::commitToDisk(clique)
                }]
            items << [
                "add to Starlight Node", 
                lambda{
                    node = StarlightMakeAndOrSelectNodeQuest::makeAndOrSelectNodeOrNull()
                    next if node.nil?
                    StarlightContents::issueClaimGivenNodeAndEntity(node, clique)
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
                        NyxObjects::destroy(clique["uuid"])
                        return
                    end
                }]
            clique["targets"]
                .each{|target| 
                    items << ["[A10495] #{A10495::targetToString(target)}", lambda{ A10495Navigation::visit(target) }] 
                }

            StarlightContents::getNodesForEntity(clique)
                .sort{|n1, n2| n1["name"] <=> n2["name"] }
                .each{|node| items << ["[node] #{StarlightNodes::nodeToString(node)}", lambda{ StarlightUserInterface::nodeDive(node) }] }

            status = LucilleCore::menuItemsWithLambdas(items) # Boolean # Indicates whether an item was chosen
            break if !status
        }
    end

    # Cliques::visitGivenCliques(cliques)
    def self.visitGivenCliques(cliques)
        loop {
            clique = LucilleCore::selectEntityFromListOfEntitiesOrNull("clique", cliques, lambda{|clique| Cliques::cliqueToString(clique) })
            break if clique.nil?
            Cliques::cliqueDive(clique)
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
                NyxObjects::getObjects("clique-933c2260-92d1-4578-9aaf-cd6557c664c6")
                    .each{|clique|
                        uuid = clique["uuid"]
                        tags1 = clique["tags"]
                        tags2 = tags1.map{|tag| renameTagIfNeeded.call(tag, oldname, newname) }
                        if tags1.join(':') != tags2.join(':') then
                            clique["tags"] = tags2
                            NyxObjects::commitToDisk(clique)
                        end
                    }
            end
            if operation == "clique dive (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                clique = NyxObjects::getOrNull(uuid)
                if clique then
                    Cliques::cliqueDive(clique)
                else
                    puts "Could not find clique for uuid (#{uuid})"
                end
            end
            if operation == "repair json (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                clique = NyxObjects::getOrNull(uuid)
                if clique then
                    cliquejson = CatalystCommon::editTextUsingTextmate(JSON.pretty_generate(clique))
                    clique = JSON.parse(cliquejson)
                    NyxObjects::commitToDisk(clique)
                else
                    puts "Could not find clique for uuid (#{uuid})"
                end
            end
            if operation == "make new clique" then
                Cliques::issueCliqueInteractivelyOrNull(true)
            end
            if operation == "show newly created cliques" then
                cliques = NyxObjects::getObjects("clique-933c2260-92d1-4578-9aaf-cd6557c664c6")
                            .sort{|p1, p2| p1["creationTimestamp"] <=> p2["creationTimestamp"] }
                            .reverse
                            .first(20)
                Cliques::visitGivenCliques(cliques)
            end
            if operation == "clique destroy (uuid)" then
                uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
                clique = NyxObjects::getOrNull(uuid)
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
        NyxObjects::getObjects("clique-933c2260-92d1-4578-9aaf-cd6557c664c6")
            .select{|clique| clique["description"].downcase.include?(searchPattern.downcase) }
    end

    # CliquesMakeAndOrSelectQuest::makeAndOrSelectCliqueOrNullPatternToCliquesDescriptions(searchPattern)
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
                    return [ Cliques::cliqueToString(clique) , lambda { Cliques::cliqueDive(clique) } ]
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
end

class CliquesNavigation

    # CliquesNavigation::mainNavigation()
    def self.mainNavigation()
        fragment = LucilleCore::askQuestionAnswerAsString("search and visit: fragment: ")
        return nil if fragment.nil?
        items = CliquesSearch::search(fragment)
        CliquesSearch::diveSearchResults(items)
    end
end

class CliquesMakeAndOrSelectQuest

    # CliquesMakeAndOrSelectQuest::makeAndOrSelectCliqueOrNull()
    def self.makeAndOrSelectCliqueOrNull()
        puts "-> You are on a selection Quest [selecting a clique]"
        puts "-> I am going to make you select one from existing and if that doesn't work, I will make you create a new one [with extensions if you want]"
        LucilleCore::pressEnterToContinue()
        clique = Cliques::selectCliqueFromExistingOrNull()
        return clique if clique
        puts "-> You are on a selection Quest [selecting a clique]"
        if LucilleCore::askQuestionAnswerAsBoolean("-> You have not selected any of the existing, would you like to make one ? ") then
            clique = Cliques::issue1CliqueInteractivelyOrNull()
            return nil if clique.nil?
            puts "-> You are on a selection Quest [selecting a clique]"
            puts "-> You have created '#{node["description"]}'"
            option1 = "quest: return '#{node["description"]}' immediately"
            option2 = "quest: dive first"
            options = [ option1, option2 ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("options", options)
            if option == option1 then
                return clique
            end
            if option == option2 then
                Cliques::cliqueDive(clique)
                return clique
            end
        end
    end
end
