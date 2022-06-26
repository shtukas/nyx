class Cliques

    # Cliques::findRemovableObjectOrNull(objects)
    def self.findRemovableObjectOrNull(objects)
        objects.combination(2).each{|pair|
            obj1, obj2 = pair
            if Genealogy::object1ShouldBeReplacedByObject2(obj1, obj2) then
                return obj1
            end
            if Genealogy::object1ShouldBeReplacedByObject2(obj2, obj1) then
                return obj2
            end
        }
        nil
    end

    # Cliques::garbageCollectionAutomatic(objects, killer)
    def self.garbageCollectionAutomatic(objects, killer)
        loop {
            obj = Cliques::findRemovableObjectOrNull(objects)
            return objects if obj.nil?
            killer.call(obj)
            objects = objects.reject{|object| object["variant"] == obj["variant"] }
        }
        objects
    end

    # Cliques::garbageCollectLocalCliqueAutomatic(uuid)
    def self.garbageCollectLocalCliqueAutomatic(uuid)
        clique = Librarian::getClique(uuid)
        Cliques::garbageCollectionAutomatic(clique, lambda{|item| Librarian::destroyVariantNoEvent(item["variant"]) })
    end

    # Cliques::garbageCollectCentralCliqueAutomatic(uuid)
    def self.garbageCollectCentralCliqueAutomatic(uuid)
        clique = StargateCentralObjects::getClique(uuid)
        Cliques::garbageCollectionAutomatic(clique, lambda{|item| StargateCentralObjects::destroyVariantNoEvent(item["variant"]) })
    end

    # Cliques::reduceLocalCliqueToOne(uuid)
    def self.reduceLocalCliqueToOne(uuid)
        clique = Librarian::getClique(uuid)
        if clique.size == 1 then
            return clique[0]
        end
        Cliques::garbageCollectLocalCliqueAutomatic(uuid)
        clique = Librarian::getClique(uuid)
        if clique.size == 1 then
            return clique[0]
        end
        puts JSON.pretty_generate(clique).green
        puts "Use the information above to select the correct version"
        variant = LucilleCore::askQuestionAnswerAsString("variant (to keep as new descendant): ")
        object = clique.select{|o| o["variant"] == variant }.first
        if object.nil? then
            raise "(error: 2f1994d5-759d-42cc-8edc-b6979c2a62b6) this is your fault"
        end
        genealogy = clique.map{|o| o["lxGenealogyAncestors"] }.flatten.uniq
        object["lxGenealogyAncestors"] = genealogy + [ SecureRandom.uuid ]
        Librarian::commitIdentical(object)
        Cliques::garbageCollectLocalCliqueAutomatic(uuid)
        clique = Librarian::getClique(uuid)
        puts JSON.pretty_generate(clique).green
        if clique.size != 1 then
            raise "(error: 09f60a03-fd8c-4aeb-8b2b-fb6f97d024e7) this should not happen"
        end
        clique[0]
    end
end
