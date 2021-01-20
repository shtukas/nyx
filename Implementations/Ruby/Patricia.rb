
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
        targets = Arrows::getTargetsForSource(object)
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
        LucilleCore::selectEntityFromListOfEntitiesOrNull("target", Arrows::getTargetsForSource(object), lambda{|t| Patricia::toString(t) })
    end

    # Patricia::selectZeroOrMoreTargetsFromThisObject(object)
    def self.selectZeroOrMoreTargetsFromThisObject(object)
        selected, _ = LucilleCore::selectZeroOrMore("target", [], Arrows::getTargetsForSource(object), lambda{|t| Patricia::toString(t) })
        selected
    end

    # Patricia::selectOneParentOfThisObjectOrNull(object)
    def self.selectOneParentOfThisObjectOrNull(object)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("target", Arrows::getSourcesForTarget(object), lambda{|t| Patricia::toString(t) })
    end

    # --------------------------------------------------
    # Maker

    # Patricia::makeNewObjectOrNull()
    def self.makeNewObjectOrNull()
        Quarks::issueNewQuarkInteractivelyOrNull()
    end

    # --------------------------------------------------
    # Architect

    # Patricia::moveTargetToNewDxThread(quark, existingDxParent)
    def self.moveTargetToNewDxThread(quark, existingDxParent)
        dx2 = DxThreads::selectOneExistingDxThreadOrNull()
        return if dx2.nil?
        Arrows::issueOrException(dx2, quark)
        Arrows::unlink(existingDxParent, quark)
    end

    # Patricia::selectDxThreadIssueNewQuark()
    def self.selectDxThreadIssueNewQuark()
        dxthread = DxThreads::selectOneExistingDxThreadOrNull()
        return if dxthread.nil?
        datapoint = Patricia::makeNewObjectOrNull()
        return if datapoint.nil?
        Arrows::issueOrException(dxthread, datapoint)
        Patricia::landing(datapoint)
    end
end
