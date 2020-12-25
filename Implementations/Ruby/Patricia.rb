
# encoding: UTF-8

class Patricia

    # -----------------------------------------------
    # is

    # Patricia::isQuark(object)
    def self.isQuark(object)
        object["nyxNxSet"] == "d65674c7-c8c4-4ed4-9de9-7c600b43eaab"
    end

    # Patricia::isWave(object)
    def self.isWave(object)
        object["nyxNxSet"] == "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4"
    end

    # Patricia::isDxThread(object)
    def self.isDxThread(object)
        object["nyxNxSet"] == "2ed4c63e-56df-4247-8f20-e8d220958226"
    end

    # -----------------------------------------------
    # gets

    # Patricia::toString(object)
    def self.toString(object)
        if Patricia::isQuark(object) then
            return Quarks::toString(object)
        end
        if Patricia::isWave(object) then
            return Waves::toString(object)
        end
        if Patricia::isDxThread(object) then
            return DxThreads::toString(object)
        end
        puts object
        raise "[error: d4c62cad-0080-4270-82a9-81b518c93c0e]"
    end

    # -----------------------------------------------
    # operations

    # Patricia::landing(object)
    def self.landing(object)
        if Patricia::isQuark(object) then
            Quarks::landing(object)
            return
        end
        if Patricia::isWave(object) then
            Waves::waveDive(object)
            return 
        end
        if Patricia::isDxThread(object) then
            return DxThreads::landing(object)
        end
        puts object
        raise "[error: fb2fb533-c9e5-456e-a87f-0523219e91b7]"
    end

    # Patricia::open1(object)
    def self.open1(object)
        if Patricia::isQuark(object) then
            Quarks::open1(object)
            return
        end
        puts object
        raise "[error: 710c5e92-6436-4ec8-8d3d-302bdf361104]"
    end

    # Patricia::destroy(object)
    def self.destroy(object)
        if Patricia::isQuark(object) then
            Quarks::destroyQuark(object)
            return
        end
        puts object
        raise "[error: 09e17b29-8620-4345-b358-89c58c248d6f]"
    end

    # --------------------------------------------------
    # User Interface (Part 1)

    # Patricia::selectOneTargetOrNullDefaultToSingletonWithConfirmation(object)
    def self.selectOneTargetOrNullDefaultToSingletonWithConfirmation(object)
        targets = TargetOrdinals::getTargetsForSourceInOrdinalOrder(object)
        if targets.size == 0 then
            return nil
        end
        if targets.size == 1 then
            if LucilleCore::askQuestionAnswerAsBoolean("selecting target: '#{Patricia::toString(targets[0])}' confirm ? ", true) then
                return targets[0]
            end
            return nil
        end
        LucilleCore::selectEntityFromListOfEntitiesOrNull("target", targets, lambda{|target| Patricia::toString(target) })
    end

    # Patricia::selectOneTargetOfThisObjectOrNull(object)
    def self.selectOneTargetOfThisObjectOrNull(object)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("target", TargetOrdinals::getTargetsForSourceInOrdinalOrder(object), lambda{|t| Patricia::toString(t) })
    end

    # Patricia::selectZeroOrMoreTargetsFromThisObject(object)
    def self.selectZeroOrMoreTargetsFromThisObject(object)
        selected, _ = LucilleCore::selectZeroOrMore("target", [], TargetOrdinals::getTargetsForSourceInOrdinalOrder(object), lambda{|t| Patricia::toString(t) })
        selected
    end

    # Patricia::selectOneParentOfThisObjectOrNull(object)
    def self.selectOneParentOfThisObjectOrNull(object)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("target", Arrows::getSourcesForTarget(object), lambda{|t| Patricia::toString(t) })
    end

    # --------------------------------------------------
    # User Interface (Part 2)

    # Patricia::mxSourcing(object, mx)
    def self.mxSourcing(object, mx)
        Arrows::getSourcesForTarget(object).each{|source|
            mx.item(
                "source: #{Patricia::toString(source)}",
                lambda { Patricia::landing(source) }
            )
        }
    end

    # Patricia::mxTargetting(object, mx)
    def self.mxTargetting(object, mx)
        targets = TargetOrdinals::getTargetsForSourceInOrdinalOrder(object)
        targets
            .each{|target|
                mx.item("target ( #{"%6.3f" % TargetOrdinals::getTargetOrdinal(object, target)} ) #{Patricia::toString(target)}", lambda { 
                    Patricia::landing(target) 
                })
            }
    end

    # Patricia::mxParentsManagement(object, mx)
    def self.mxParentsManagement(object, mx)
        mx.item("add parent".yellow, lambda {
            o1 = Patricia::makeNewObjectOrNull()
            return if o1.nil?
            Arrows::issueOrException(o1, object)
        })

        mx.item("remove parent".yellow, lambda {
            parents = Arrows::getSourcesForTarget(object)
            parent = LucilleCore::selectEntityFromListOfEntitiesOrNull("parent", parents, lambda { |parent| Patricia::toString(parent) })
            return if parent.nil?
            Arrows::unlink(parent, object)
        })
    end

    # Patricia::mxTargetsManagement(object, mx)
    def self.mxTargetsManagement(object, mx)

        mx.item("add new target at ordinal".yellow, lambda { 
            o1 = Patricia::makeNewObjectOrNull()
            return if o1.nil?
            Arrows::issueOrException(object, o1)
            ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
            if ordinal == 0 then
                ordinal = ([1] + TargetOrdinals::getTargetsForSourceInOrdinalOrder(object).map{|target| TargetOrdinals::getTargetOrdinal(object, target) }).max
            end
            TargetOrdinals::setTargetOrdinal(object, o1, ordinal)
        })

        mx.item("update target's ordinal".yellow, lambda { 
            target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", TargetOrdinals::getTargetsForSourceInOrdinalOrder(object), lambda{|t| Patricia::toString(t) })
            return if target.nil?
            ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
            TargetOrdinals::setTargetOrdinal(object, target, ordinal)
        })

        mx.item("remove target".yellow, lambda { 
            targets = TargetOrdinals::getTargetsForSourceInOrdinalOrder(object)
            target = LucilleCore::selectEntityFromListOfEntitiesOrNull("target", targets, lambda { |target| Patricia::toString(target) })
            return if target.nil?
            Arrows::unlink(object, target)
        })
    end

    # Patricia::mxMoveToNewParent(object, mx)
    def self.mxMoveToNewParent(object, mx)
        mx.item("move to new parent".yellow, lambda {
            sources = Arrows::getSourcesForTarget(object)
            newparent = Patricia::makeNewObjectOrNull()
            return if newparent.nil?
            Arrows::issueOrException(newparent, object)
            sources.each{|source|
                Arrows::unlink(source, object)
            }
        })
    end

    # --------------------------------------------------
    # Maker

    # Patricia::makeNewObjectOrNull()
    def self.makeNewObjectOrNull()
        loop {
            options = ["line", "quark"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            return nil if option.nil?
            if option == "line" then
                line = LucilleCore::askQuestionAnswerAsString("line: ")
                quark = Quarks::makeLine(line)
                quark["description"] = line
                NSCoreObjects::put(quark)
                return quark
            end
            if option == "quark" then
                object = Quarks::issueNewQuarkInteractivelyOrNull()
                return object if object
            end
        }
    end

    # --------------------------------------------------
    # Architect

    # Patricia::makeNewUnsavedDatapointForTransmutationInteractivelyOrNull()
    def self.makeNewUnsavedDatapointForTransmutationInteractivelyOrNull()
        Quarks::makeUnsavedQuarkForTransmutationInteractivelyOrNull()
    end
end
