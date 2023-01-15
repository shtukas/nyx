# encoding: UTF-8

class NxTodos

    # --------------------------------------------------
    # IO

    # NxTodos::repositoryFolderPath()
    def self.repositoryFolderPath()
        "#{Config::pathToDataCenter()}/NxTodo"
    end

    # NxTodos::filepath(uuid)
    def self.filepath(uuid)
        "#{NxTodos::repositoryFolderPath()}/#{uuid}.json"
    end

    # NxTodos::commit(object)
    def self.commit(object)
        FileSystemCheck::fsck_MikuTypedItem(object, true)
        filepath = NxTodos::filepath(object["uuid"])
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(object)) }
    end

    # NxTodos::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = "#{NxTodos::repositoryFolderPath()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # NxTodos::itemsEnumerator()
    def self.itemsEnumerator()
        Enumerator.new do |items|
            LucilleCore::locationsAtFolder(NxTodos::repositoryFolderPath())
            .select{|filepath| filepath[-5, 5] == ".json" }
            .each{|filepath|
                items << JSON.parse(IO.read(filepath))
            }
        end
    end

    # NxTodos::itemsForNxProject(projectId)
    def self.itemsForNxProject(projectId)
        NxTodos::itemsEnumerator()
            .select{|item|
                item["projectId"] == projectId
            }
    end

    # NxTodos::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxTodos::filepath(uuid)
        if File.exists?(filepath) then
            FileUtils.rm(filepath)
        end
    end

    # --------------------------------------------------
    # Makers

    # NxTodos::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = CommonUtils::timeStringL22()
        nx113 = Nx113Make::interactivelyMakeNx113OrNull()
        projectId = NxProjects::interactivelySelectProject()["uuid"]
        projectposition = NxProjects::interactivelyDecideProjectPosition(projectId)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
            "projectId"       => projectId,
            "projectposition" => projectposition
        }
        NxTodos::commit(item)
        item
    end

    # NxTodos::issueConsumingNxOndate(nxondate)
    def self.issueConsumingNxOndate(nxondate)
        item = nxondate.clone
        project = NxProjects::interactivelySelectProject()
        projectposition = NxProjects::nextPositionForProject(project["uuid"])
        item["uuid"] = CommonUtils::timeStringL22()
        item["mikuType"] = "NxTodo"
        item["projectId"] = project["uuid"]
        item["projectposition"] = projectposition
        NxTodos::commit(item)
        NxOndates::destroy(nxondate["uuid"])
        item
    end

    # NxTodos::issueConsumingNxTriage(nxtriage)
    def self.issueConsumingNxTriage(nxtriage)

        puts "description: #{nxtriage["description"].green}"
        d = LucilleCore::askQuestionAnswerAsString("description (empty to confirm existing): ")

        if d == "" then
            description = nxtriage["description"]
        else
            description = d
        end

        item = nxtriage.clone
        project = NxProjects::interactivelySelectProject()
        projectposition = NxProjects::interactivelyDecideProjectPosition(project["uuid"])
        item["uuid"] = CommonUtils::timeStringL22()
        item["description"] = description
        item["mikuType"] = "NxTodo"
        item["projectId"] = project["uuid"]
        item["projectposition"] = projectposition
        NxTodos::commit(item)
        NxTriages::destroy(nxtriage["uuid"])
        item
    end

    # --------------------------------------------------
    # Data

    # NxTodos::toString(item)
    def self.toString(item)
        nx113str = Nx113Access::toStringOrNull(" ", item["nx113"], "")
        "(todo) #{item["description"]}#{nx113str}"
    end

    # NxTodos::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(todo) #{item["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # NxTodos::access(item)
    def self.access(item)
        puts NxTodos::toString(item).green
        if item["nx113"] then
            Nx113Access::access(item["nx113"])
        end
    end

    # NxTodos::edit(item) # item
    def self.edit(item)
        if item["nx113"].nil? then
            puts "This item doesn't have a Nx113 attached to it"
            status = LucilleCore::askQuestionAnswerAsBoolean("Would you like to edit the description instead ? ")
            if status then
                PolyActions::editDescription(item)
                return NxTodos::getOrNull(item["uuid"])
            else
                return item
            end
        end
        Nx113Edit::editNx113Carrier(item)
        NxTodos::getOrNull(item["uuid"])
    end

    # NxTodos::probe(item)
    def self.probe(item)
        loop {
            system("clear")
            item = NxTodos::getOrNull(item["uuid"])
            puts NxTodos::toString(item)
            actions = ["access", "update description", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "access" then
                NxTodos::access(item)
            end
            if action == "update description" then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                item["description"] = description
                NxTodos::commit(item)
            end
            if action == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("Confirm destruction of NxTodo '#{NxTodos::toString(item)}' ? ") then
                    NxTodos::destroy(item["uuid"])
                    PolyActions::garbageCollectionAfterItemDeletion(item)
                    return
                end
            end
        }
    end
end
