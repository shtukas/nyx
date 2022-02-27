# encoding: UTF-8

class NyxNetwork

    # NyxNetwork::selectEntityFromGivenEntitiesOrNull(entities)
    def self.selectEntityFromGivenEntitiesOrNull(entities)
        item = Utils2::selectOneObjectUsingInteractiveInterfaceOrNull(entities, lambda{|entity| Nx31::toString(entity) })
        return nil if item.nil?
        item
    end

    # -- connects -----------------------------------------------

    # NyxNetwork::linked(entity)
    def self.linked(entity)
         Links::entities(entity["uuid"])
    end

    # NyxNetwork::connectToOtherArchitectured(entity)
    def self.connectToOtherArchitectured(entity)
        other = Nx31::architectOrNull()
        return if other.nil?
        Links::link(entity["uuid"], other["uuid"])
    end

    # NyxNetwork::disconnectFromOtherInteractively(entity)
    def self.disconnectFromOtherInteractively(entity)
        other = LucilleCore::selectEntityFromListOfEntitiesOrNull("connected", NyxNetwork::linked(entity), lambda{|entity| Nx31::toString(entity)})
        return if other.nil?
        Links::unlink(entity["uuid"], other["uuid"])
    end

    # NyxNetwork::networkReplace(uuid1, uuid2)
    # If we want to update the uuid of an element (original: uuid1, new: uuid2)
    # Then we use this function to give to uuid2 the same connects as uuid1 
    def self.networkReplace(uuid1, uuid2)
        Links::entities(uuid1).each{|entity|
            Links::link(uuid2, entity["uuid"])
        }
    end

    # ----------------------------------------------------
    # Deep lines functions

    # NyxNetwork::nomaliseDescriptionForDeepLineSearch(str)
    def self.nomaliseDescriptionForDeepLineSearch(str)
        str.split("::")
            .map{|element| element.strip }
            .join(" :: ")
    end

    # NyxNetwork::computeDeepLineNodes(entity)
    def self.computeDeepLineNodes(entity)
        normalisedDescription = NyxNetwork::nomaliseDescriptionForDeepLineSearch(entity["description"])
        Nx31::mikus().select{|nx31| NyxNetwork::nomaliseDescriptionForDeepLineSearch(nx31["description"]).start_with?(normalisedDescription) }
    end

    # NyxNetwork::computeDeepLineConnectedEntities(entity)
    def self.computeDeepLineConnectedEntities(entity)
        NyxNetwork::computeDeepLineNodes(entity)
            .map{|node| Links::entities(node["uuid"]) }
            .flatten
            .reduce([]){|selected, y|
                if selected.none?{|x| x["uuid"] == y["uuid"] } then
                    selected << y
                end
                selected
            }
    end


    # -----------------------------------------------------
    # Special Circumstances

    # NyxNetwork::mirrorLinksTagsNotes(node1, node2)
    def self.mirrorLinksTagsNotes(node1, node2)
        Links::entities(node1["uuid"]).each{|nx31|
            puts "linking '#{Nx31::toString(nx31)}' to '#{Nx31::toStringWithTrace4(node2)}'"
            Links::link(nx31["uuid"], node2["uuid"])
        }

        Links::entities(node2["uuid"]).each{|nx31|
            puts "linking '#{Nx31::toString(nx31)}' to '#{Nx31::toStringWithTrace4(node1)}'"
            Links::link(nx31["uuid"], node1["uuid"])
        }

        Tags::tagsForOwner(node1["uuid"]).each{|tag|
            puts "tagging '#{tag["payload"]}' to '#{Nx31::toStringWithTrace4(node2)}'"
            Tags::insert(SecureRandom.uuid, node2["uuid"], tag["payload"])
        }

        Tags::tagsForOwner(node2["uuid"]).each{|tag|
            puts "tagging '#{tag["payload"]}' to '#{Nx31::toStringWithTrace4(node1)}'"
            Tags::insert(SecureRandom.uuid, node1["uuid"], tag["payload"])
        }

        LibrarianNotes::getObjectNotes(node1["uuid"]).each{|note|
            puts "note: #{note["text"]} to '#{Nx31::toStringWithTrace4(node2)}'"
            LibrarianNotes::addNote(node2["uuid"], note["text"])
        }

        LibrarianNotes::getObjectNotes(node2["uuid"]).each{|note|
            puts "note: #{note["text"]} to '#{Nx31::toStringWithTrace4(node1)}'"
            LibrarianNotes::addNote(node1["uuid"], note["text"])
        }
    end
end
