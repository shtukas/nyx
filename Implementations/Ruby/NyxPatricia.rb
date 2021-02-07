
# encoding: UTF-8

class NyxPatricia

    # NyxPatricia::isNereidElement(element)
    def self.isNereidElement(element)
        !element["payload"].nil?
    end

    # NyxPatricia::isNX141FSCacheElement(element)
    def self.isNX141FSCacheElement(element)
        element["nyxElementType"] == "736ec8c8-daa6-48cf-8d28-84cfca79bedc"
    end

    # NyxPatricia::isTimelineItem(element)
    def self.isTimelineItem(element)
        element["nyxElementType"] == "ea9f4f69-1c8c-49c9-b644-8854c1be75d8"
    end

    # NyxPatricia::isClassifier(item)
    def self.isClassifier(item)
        item["nyxElementType"] == "22f244eb-4925-49be-bce6-db58c2fb489a"
    end

    # NyxPatricia::isCuratedListing(item)
    def self.isCuratedListing(item)
        item["nyxElementType"] == "30991912-a9f2-426d-9b62-ec942c16c60a"
    end

    # NyxPatricia::isQuark(object)
    def self.isQuark(object)
        object["nyxNxSet"] == "d65674c7-c8c4-4ed4-9de9-7c600b43eaab"
    end

    # NyxPatricia::isWave(object)
    def self.isWave(object)
        object["nyxNxSet"] == "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4"
    end

    # NyxPatricia::isDxThread(object)
    def self.isDxThread(object)
        object["nyxNxSet"] == "2ed4c63e-56df-4247-8f20-e8d220958226"
    end

    # -------------------------------------------------------

    # NyxPatricia::getDX7ByUUIDOrNull(uuid)
    def self.getDX7ByUUIDOrNull(uuid)
        item = NereidInterface::getElementOrNull(uuid)
        return item if item

        item = NX141FSCacheElement::getElementByUUIDOrNull(uuid)
        return item if item

        item = TimelineItems::getTimelineItemForUUIDOrNull(uuid)
        return item if item

        item = Classifiers::getClassifierByUUIDOrNull(uuid)
        return item if item

        item = CuratedListings::getCuratedListingByUUIDOrNull(uuid)
        return item if item

        nil
    end

    # NyxPatricia::toString(item)
    def self.toString(item)
        if NyxPatricia::isNereidElement(item) then
            return NereidInterface::toString(item)
        end
        if NyxPatricia::isNX141FSCacheElement(item) then
            return NX141FSCacheElement::toString(item)
        end
        if NyxPatricia::isTimelineItem(item) then
            return TimelineItems::toString(item)
        end
        if NyxPatricia::isClassifier(item) then
            return Classifiers::toString(item)
        end
        if NyxPatricia::isCuratedListing(item) then
            return CuratedListings::toString(item)
        end
        if NyxPatricia::isQuark(item) then
            return Quarks::toString(item)
        end
        if NyxPatricia::isWave(item) then
            return Waves::toString(item)
        end
        if NyxPatricia::isDxThread(item) then
            return DxThreads::toString(item)
        end
        puts item
        raise "[error: d4c62cad-0080-4270-82a9-81b518c93c0e]"
    end

    # NyxPatricia::dx7access(item)
    def self.dx7access(item)
        if NyxPatricia::isNereidElement(item) then
            NereidInterface::access(item)
            return
        end
        if NyxPatricia::isNX141FSCacheElement(item) then
            NX141FSCacheElement::access(item["nx141"])
            return
        end
        if NyxPatricia::isTimelineItem(item) then
            TimelineItems::landing(item)
            return
        end
        if NyxPatricia::isClassifier(item) then
            Classifiers::landing(item)
            return
        end
        if NyxPatricia::isCuratedListing(item) then
            CuratedListings::landing(item)
            return
        end
        puts item
        raise "error: 22830b8a-f43d-4f0e-b419-21f809d99404"
    end

    # NyxPatricia::landing(item)
    def self.landing(item)
        if NyxPatricia::isNereidElement(item) then
            NereidProxyOperator::landing(item)
            return
        end
        if NyxPatricia::isNX141FSCacheElement(item) then
            NX141FSCacheElement::landing(item)
            return
        end
        if NyxPatricia::isTimelineItem(item) then
            TimelineItems::landing(item)
            return
        end
        if NyxPatricia::isClassifier(item) then
            Classifiers::landing(item)
            return
        end
        if NyxPatricia::isCuratedListing(item) then
            CuratedListings::landing(item)
            return
        end
        if NyxPatricia::isQuark(item) then
            Quarks::landing(item)
            return
        end
        if NyxPatricia::isWave(item) then
            Waves::landing(item)
            return 
        end
        if NyxPatricia::isDxThread(item) then
            return DxThreads::landing(item)
        end
        puts item
        raise "[error: fb2fb533-c9e5-456e-a87f-0523219e91b7]"
    end

    # NyxPatricia::destroy(object)
    def self.destroy(object)
        if NyxPatricia::isQuark(object) then
            Quarks::destroyQuarkAndNereidContent(object)
            return
        end
        puts object
        raise "[error: 09e17b29-8620-4345-b358-89c58c248d6f]"
    end

    # -------------------------------------------------------

    # NyxPatricia::architectDX7OrNull()
    def self.architectDX7OrNull()
        dx7 = NyxPatricia::selectOneDX7OrNull()
        return dx7 if dx7
        ops = ["Nereid Element", "Classifier", "TimelineItem", "Curated Listing"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ops)
        return if operation.nil?
        if operation == "Nereid Element" then
            return NereidInterface::interactivelyIssueNewElementOrNull()
        end
        if operation == "Classifier" then
            return Classifiers::interactivelyIssueNewClassifierOrNull()
        end
        if operation == "TimelineItem" then
            return TimelineItems::interactivelyIssueNewTimelineItemOrNull()
        end
        if operation == "Curated Listing" then
            return CuratedListings::interactivelyIssueNewCuratedListingOrNull()
        end  
    end

    # NyxPatricia::architectAddParentForDX7(item)
    def self.architectAddParentForDX7(item)
        e1 = NyxPatricia::architectDX7OrNull()
        return if e1.nil?
        NyxArrows::issueArrow(e1["uuid"], item["uuid"])
    end

    # NyxPatricia::architectAddChildForDX7(item)
    def self.architectAddChildForDX7(item)
        e1 = NyxPatricia::architectDX7OrNull()
        return if e1.nil?
        NyxArrows::issueArrow(item["uuid"], e1["uuid"])
    end

    # NyxPatricia::selectAndRemoveOneParentFromDX7(item)
    def self.selectAndRemoveOneParentFromDX7(item)
        parents = NyxArrows::getParentsUUIDs(item["uuid"])
                    .map{|uuid| NyxPatricia::getDX7ByUUIDOrNull(uuid) }
                    .compact
        return if parents.empty?
        parent = LucilleCore::selectEntityFromListOfEntitiesOrNull("parent", parents, lambda{|parent| NyxPatricia::toString(parent) })
        return if parent.nil?
        NyxArrows::deleteArrow(parent["uuid"], item["uuid"])
    end

    # NyxPatricia::selectAndRemoveOneChildFromDX7(item)
    def self.selectAndRemoveOneChildFromDX7(item)
        children = NyxArrows::getChildrenUUIDs(item["uuid"])
                    .map{|uuid| NyxPatricia::getDX7ByUUIDOrNull(uuid) }
                    .compact
        return if children.empty?
        child = LucilleCore::selectEntityFromListOfEntitiesOrNull("child", children, lambda{|child| NyxPatricia::toString(child) })
        return if child.nil?
        NyxArrows::deleteArrow(item["uuid", child["uuid"]])
    end

    # NyxPatricia::computeNew21stOrdinalForDxThread(dxthread)
    def self.computeNew21stOrdinalForDxThread(dxthread)
        ordinals = DxThreadQuarkMapping::dxThreadToQuarksInOrder(dxthread, 22)
                    .map{|quark| DxThreadQuarkMapping::getDxThreadQuarkOrdinal(dxthread, quark) }
                    .sort
        ordinals = ordinals.drop(19).take(2)
        if ordinals.size < 2 then
            return DxThreadQuarkMapping::getNextOrdinal()
        end
        (ordinals[0]+ordinals[1]).to_f/2
    end

    # NyxPatricia::moveTargetToNewDxThread(quark, dxParentOpt or null)
    def self.moveTargetToNewDxThread(quark, dxParentOpt)
        dx2 = DxThreads::selectOneExistingDxThreadOrNull()
        return if dx2.nil?
        ordinal = DxThreads::determinePlacingOrdinalForThread(dx2)
        DxThreadQuarkMapping::insertRecord(dx2, quark, ordinal)
    end

    # NyxPatricia::getQuarkPossiblyArchitectedOrNull(quarkOpt, dxThreadOpt)
    def self.getQuarkPossiblyArchitectedOrNull(quarkOpt, dxThreadOpt)
        quark = quarkOpt ? quarkOpt : Quarks::issueNewQuarkInteractivelyOrNull()
        return nil if quark.nil?
        dxthread = dxThreadOpt ? dxThreadOpt : DxThreads::selectOneExistingDxThreadOrNull()
        ordinal = DxThreads::determinePlacingOrdinalForThread(dxthread)
        DxThreadQuarkMapping::insertRecord(dxthread, quark, ordinal)
        NyxPatricia::landing(quark)
        quark
    end

    # -------------------------------------------------------

    # NyxPatricia::nyxSearchItemsAll()
    def self.nyxSearchItemsAll()
        searchItems = [
            NereidProxyOperator::nyxSearchItems(),
            NX141FSCacheElement::nyxSearchItems(),
            TimelineItems::nyxSearchItems(),
            Classifiers::nyxSearchItems(),
            CuratedListings::nyxSearchItems()
        ]
        .flatten
    end

    # NyxPatricia::selectOneDX7OrNull()
    def self.selectOneDX7OrNull()
        searchItem = NyxUtils::selectOneOrNull(NyxPatricia::nyxSearchItemsAll(), lambda{|item| item["announce"] })
        return nil if searchItem.nil?
        searchItem["payload"]
    end

    # NyxPatricia::generalSearchLoop()
    def self.generalSearchLoop()
        loop {
            dx7 = NyxPatricia::selectOneDX7OrNull()
            break if dx7.nil? 
            NyxPatricia::landing(dx7)
        }
    end
end
