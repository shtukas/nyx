
# encoding: UTF-8

class Patricia

    # Patricia::isNereidElement(element)
    def self.isNereidElement(element)
        !element["payload"].nil?
    end

    # Patricia::isNX141FSCacheElement(element)
    def self.isNX141FSCacheElement(element)
        element["nyxElementType"] == "736ec8c8-daa6-48cf-8d28-84cfca79bedc"
    end

    # Patricia::isTimelineItem(element)
    def self.isTimelineItem(element)
        element["nyxElementType"] == "ea9f4f69-1c8c-49c9-b644-8854c1be75d8"
    end

    # Patricia::isClassifier(item)
    def self.isClassifier(item)
        item["nyxElementType"] == "22f244eb-4925-49be-bce6-db58c2fb489a"
    end

    # Patricia::isCuratedListing(item)
    def self.isCuratedListing(item)
        item["nyxElementType"] == "30991912-a9f2-426d-9b62-ec942c16c60a"
    end

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

    # -------------------------------------------------------

    # Patricia::getDX7ByUUIDOrNull(uuid)
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

    # Patricia::toString(item)
    def self.toString(item)
        if Patricia::isNereidElement(item) then
            return NereidInterface::toString(item)
        end
        if Patricia::isNX141FSCacheElement(item) then
            return NX141FSCacheElement::toString(item)
        end
        if Patricia::isTimelineItem(item) then
            return TimelineItems::toString(item)
        end
        if Patricia::isClassifier(item) then
            return Classifiers::toString(item)
        end
        if Patricia::isCuratedListing(item) then
            return CuratedListings::toString(item)
        end
        if Patricia::isQuark(item) then
            return Quarks::toString(item)
        end
        if Patricia::isWave(item) then
            return Waves::toString(item)
        end
        if Patricia::isDxThread(item) then
            return DxThreads::toString(item)
        end
        puts item
        raise "[error: d4c62cad-0080-4270-82a9-81b518c93c0e]"
    end

    # Patricia::dx7access(item)
    def self.dx7access(item)
        if Patricia::isNereidElement(item) then
            NereidInterface::access(item)
            return
        end
        if Patricia::isNX141FSCacheElement(item) then
            NX141FSCacheElement::access(item["nx141"])
            return
        end
        if Patricia::isTimelineItem(item) then
            TimelineItems::landing(item)
            return
        end
        if Patricia::isClassifier(item) then
            Classifiers::landing(item)
            return
        end
        if Patricia::isCuratedListing(item) then
            CuratedListings::landing(item)
            return
        end
        puts item
        raise "error: 22830b8a-f43d-4f0e-b419-21f809d99404"
    end

    # Patricia::landing(item)
    def self.landing(item)
        if Patricia::isNereidElement(item) then
            NyxNereidElements::landing(item)
            return
        end
        if Patricia::isNX141FSCacheElement(item) then
            NX141FSCacheElement::landing(item)
            return
        end
        if Patricia::isTimelineItem(item) then
            TimelineItems::landing(item)
            return
        end
        if Patricia::isClassifier(item) then
            Classifiers::landing(item)
            return
        end
        if Patricia::isCuratedListing(item) then
            CuratedListings::landing(item)
            return
        end
        if Patricia::isQuark(item) then
            Quarks::landing(item)
            return
        end
        if Patricia::isWave(item) then
            Waves::landing(item)
            return 
        end
        if Patricia::isDxThread(item) then
            return DxThreads::landing(item)
        end
        puts item
        raise "[error: fb2fb533-c9e5-456e-a87f-0523219e91b7]"
    end

    # Patricia::destroy(object)
    def self.destroy(object)
        if Patricia::isQuark(object) then
            Quarks::destroyQuarkAndNereidContent(object)
            return
        end
        puts object
        raise "[error: 09e17b29-8620-4345-b358-89c58c248d6f]"
    end

    # -------------------------------------------------------

    # Patricia::architectDX7OrNull()
    def self.architectDX7OrNull()
        dx7 = Patricia::selectOneDX7OrNull()
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

    # Patricia::architectAddParentForDX7(item)
    def self.architectAddParentForDX7(item)
        e1 = Patricia::architectDX7OrNull()
        return if e1.nil?
        NyxArrows::issueArrow(e1["uuid"], item["uuid"])
    end

    # Patricia::architectAddChildForDX7(item)
    def self.architectAddChildForDX7(item)
        e1 = Patricia::architectDX7OrNull()
        return if e1.nil?
        NyxArrows::issueArrow(item["uuid"], e1["uuid"])
    end

    # Patricia::selectAndRemoveOneParentFromDX7(item)
    def self.selectAndRemoveOneParentFromDX7(item)
        parents = NyxArrows::getParentsUUIDs(item["uuid"])
                    .map{|uuid| Patricia::getDX7ByUUIDOrNull(uuid) }
                    .compact
        return if parents.empty?
        parent = LucilleCore::selectEntityFromListOfEntitiesOrNull("parent", parents, lambda{|parent| Patricia::toString(parent) })
        return if parent.nil?
        NyxArrows::deleteArrow(parent["uuid"], item["uuid"])
    end

    # Patricia::selectAndRemoveOneChildFromDX7(item)
    def self.selectAndRemoveOneChildFromDX7(item)
        children = NyxArrows::getChildrenUUIDs(item["uuid"])
                    .map{|uuid| Patricia::getDX7ByUUIDOrNull(uuid) }
                    .compact
        return if children.empty?
        child = LucilleCore::selectEntityFromListOfEntitiesOrNull("child", children, lambda{|child| Patricia::toString(child) })
        return if child.nil?
        NyxArrows::deleteArrow(item["uuid", child["uuid"]])
    end

    # Patricia::computeNew21stOrdinalForDxThread(dxthread)
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

    # Patricia::moveTargetToNewDxThread(quark, dxParentOpt or null)
    def self.moveTargetToNewDxThread(quark, dxParentOpt)
        dx2 = DxThreads::selectOneExistingDxThreadOrNull()
        return if dx2.nil?
        ordinal = DxThreads::determinePlacingOrdinalForThread(dx2)
        DxThreadQuarkMapping::insertRecord(dx2, quark, ordinal)
    end

    # Patricia::getQuarkPossiblyArchitectedOrNull(quarkOpt, dxThreadOpt)
    def self.getQuarkPossiblyArchitectedOrNull(quarkOpt, dxThreadOpt)
        quark = quarkOpt ? quarkOpt : Quarks::issueNewQuarkInteractivelyOrNull()
        return nil if quark.nil?
        dxthread = dxThreadOpt ? dxThreadOpt : DxThreads::selectOneExistingDxThreadOrNull()
        ordinal = DxThreads::determinePlacingOrdinalForThread(dxthread)
        DxThreadQuarkMapping::insertRecord(dxthread, quark, ordinal)
        Patricia::landing(quark)
        quark
    end

    # -------------------------------------------------------

    # Patricia::nyxSearchItemsAll()
    def self.nyxSearchItemsAll()
        searchItems = [
            NyxNereidElements::nyxSearchItems(),
            NX141FSCacheElement::nyxSearchItems(),
            TimelineItems::nyxSearchItems(),
            Classifiers::nyxSearchItems(),
            CuratedListings::nyxSearchItems()
        ]
        .flatten
    end

    # Patricia::selectOneDX7OrNull()
    def self.selectOneDX7OrNull()
        searchItem = CatalystUtils::selectOneOrNull(Patricia::nyxSearchItemsAll(), lambda{|item| item["announce"] })
        return nil if searchItem.nil?
        searchItem["payload"]
    end

    # Patricia::generalSearchLoop()
    def self.generalSearchLoop()
        loop {
            dx7 = Patricia::selectOneDX7OrNull()
            break if dx7.nil? 
            Patricia::landing(dx7)
        }
    end
end
