
# encoding: UTF-8

class Patricia

    # Patricia::isNereidElement(element)
    def self.isNereidElement(element)
        !element["payload"].nil?
    end

    # Patricia::isWave(object)
    def self.isWave(object)
        object["nyxNxSet"] == "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4"
    end

    # Patricia::isDxThread(object)
    def self.isDxThread(object)
        object["nyxNxSet"] == "2ed4c63e-56df-4247-8f20-e8d220958226"
    end

    # Patricia::isQuark(object)
    def self.isQuark(object)
        object["nyxNxSet"] == "d65674c7-c8c4-4ed4-9de9-7c600b43eaab"
    end

    # Patricia::isNX141FSCacheElement(element)
    def self.isNX141FSCacheElement(element)
        element["nyxElementType"] == "736ec8c8-daa6-48cf-8d28-84cfca79bedc"
    end

    # Patricia::isNyxClassifier(item)
    def self.isNyxClassifier(item)
        item["identifier1"] == "103df1ac-2e73-4bf1-a786-afd4092161d4"
    end

    # -------------------------------------------------------

    # Patricia::getNyxNetworkNodeByUUIDOrNull(uuid)
    def self.getNyxNetworkNodeByUUIDOrNull(uuid)
        item = NereidInterface::getElementOrNull(uuid)
        return item if item

        item = NX141FSCacheElement::getElementByUUIDOrNull(uuid)
        return item if item

        item = NyxClassifierDeclarations::getClassifierByUUIDOrNull(uuid)
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
        if Patricia::isNyxClassifier(item) then
            return NyxClassifierDeclarations::toString(item)
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

    # Patricia::landing(item)
    def self.landing(item)
        if Patricia::isNereidElement(item) then
            M92::landing(item)
            return
        end
        if Patricia::isNX141FSCacheElement(item) then
            NX141FSCacheElement::landing(item)
            return
        end
        if Patricia::isNyxClassifier(item) then
            NyxClassifierDeclarations::landing(item)
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

    # -------------------------------------------------------

    # Patricia::selectOneNodeOrNull()
    def self.selectOneNodeOrNull()
        searchItem = CatalystUtils::selectOneOrNull(Patricia::nyxSearchItemsAll(), lambda{|item| item["announce"] })
        return nil if searchItem.nil?
        searchItem["payload"]
    end

    # Patricia::architectNodeOrNull()
    def self.architectNodeOrNull()
        dx7 = Patricia::selectOneNodeOrNull()
        return dx7 if dx7
        ops = ["Nereid Element", "Classifier Item"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ops)
        return if operation.nil?
        if operation == "Nereid Element" then
            return NereidInterface::interactivelyIssueNewElementOrNull()
        end
        if operation == "Classifier Item" then
            return NyxClassifierDeclarations::interactivelyIssueNewClassiferOrNull()
        end
    end

    # Patricia::linkToArchitectedNode(item)
    def self.linkToArchitectedNode(item)
        e1 = Patricia::architectNodeOrNull()
        return if e1.nil?
        Network::link(item, e1)
    end

    # Patricia::selectAndRemoveLinkedNode(item)
    def self.selectAndRemoveLinkedNode(item)
        related = Network::getLinkedObjects(item)
        return if related.empty?
        node = LucilleCore::selectEntityFromListOfEntitiesOrNull("related", related, lambda{|node| Patricia::toString(node) })
        return if node.nil?
        Network::unlink(item, node)
    end

    # -------------------------------------------------------

    # Patricia::nyxSearchItemsAll()
    def self.nyxSearchItemsAll()
        searchItems = [
            M92::nyxSearchItems(),
            NX141FSCacheElement::nyxSearchItems(),
            NyxClassifierDeclarations::nyxSearchItems()
        ]
        .flatten
    end

    # Patricia::generalSearchLoop()
    def self.generalSearchLoop()
        loop {
            dx7 = Patricia::selectOneNodeOrNull()
            break if dx7.nil? 
            Patricia::landing(dx7)
        }
    end

    # -------------------------------------------------------
end
