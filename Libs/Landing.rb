
# encoding: UTF-8

class Landing

    # Landing::removeConnected(item)
    def self.removeConnected(item)
        store = ItemStore.new()

        NetworkLinks::linkeduuids(item["uuid"]) # .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
            .each{|entityuuid|
                entity = TheIndex::getItemOrNull(entityuuid)
                next if entity.nil?
                indx = store.register(entity, false)
                puts "[#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", entity)}"
            }

        i = LucilleCore::askQuestionAnswerAsString("> remove index (empty to exit): ")

        return if i == ""

        if (indx = Interpreting::readAsIntegerOrNull(i)) then
            entity = store.get(indx)
            return if entity.nil?
            NetworkLinks::unlink(item["uuid"], entity["uuid"])
        end
    end

    # Landing::link(item)
    def self.link(item)
        newitem = Nyx::architectOneOrNull()
        return if newitem.nil?
        NetworkLinks::link(item["uuid"], newitem["uuid"])
    end

    # Landing::landing(item, isSearchAndSelect) # item or null
    def self.landing(item, isSearchAndSelect)
        if item["mikuType"] == "TxTimeCommitmentProject" then
            return TxTimeCommitmentProjects::landing(item, isSearchAndSelect)
        end
        if item["mikuType"] == "DxAionPoint" then
            return DxAionPoint::landing(item, isSearchAndSelect)
        end
        if item["mikuType"] == "DxFile" then
            return DxFile::landing(item, isSearchAndSelect)
        end
        if item["mikuType"] == "DxLine" then
            return DxLine::landing(item, isSearchAndSelect)
        end
        if item["mikuType"] == "DxText" then
            return DxText::landing(item, isSearchAndSelect)
        end
        if item["mikuType"] == "TopLevel" then
            TopLevel::access(item)
            return nil
        end
        if item["mikuType"] == "NxLine" then
            puts "landing:"
            puts JSON.pretty_generate(item)
            LucilleCore::pressEnterToContinue()
            return nil
        end
        if item["mikuType"] == "NxPerson" then
            return NxPersons::landing(item, isSearchAndSelect)
        end
        if item["mikuType"] == "NxEntity" then
            return NxEntities::landing(item, isSearchAndSelect)
        end
        if item["mikuType"] == "NxConcept" then
            return NxConcepts::landing(item, isSearchAndSelect)
        end
        if item["mikuType"] == "NxCollection" then
            return NxCollections::landing(item, isSearchAndSelect)
        end
        if item["mikuType"] == "NxTask" then
            NxTasks::landing(item, isSearchAndSelect)
        end
        if item["mikuType"] == "NxTimeline" then
            return NxTimelines::landing(item, isSearchAndSelect)
        end
        raise "(error: 1e84c68b-b602-41af-b2e9-00e66fa687ac) item: #{item}"
    end
end
