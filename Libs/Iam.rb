
# encoding: UTF-8

class Iam

    # Iam::nyxDataTypes()
    def self.nyxDataTypes()
        ["DxLine", "DxUrl", "DxText", "DxFile", "DxAionPoint", "DxUniqueString"]
    end

    # Iam::nyxAggregationTypes()
    def self.nyxAggregationTypes()
        ["NxPerson", "NxEntity", "NxConcept", "NxCollection", "NxTimeline", "NxEvent"]
    end

    # Iam::nyxNetworkTypes()
    def self.nyxNetworkTypes()
        Iam::nyxDataTypes() + Iam::nyxAggregationTypes()
    end

    # Iam::isNetworkAggregation(item)
    def self.isNetworkAggregation(item)
        Iam::nyxAggregationTypes().include?(item["mikuType"])
    end

    # Iam::nx112CarrierTypes()
    def self.nx112CarrierTypes()
        [
            "NxTask",
            "TxDated",
            "TxTimeCommitment",
            "Wave",

            "DxAionPoint",
            "DxFile",
            "DxText",
            "DxUniqueString",
            "DxUrl",
            "NxEvent"
        ]
    end

    # Iam::isNx112Carrier(item)
    def self.isNx112Carrier(item)
        Iam::nx112CarrierTypes().include?(item["mikuType"])
    end

    # Iam::isCatalystItem(item)
    def self.isCatalystItem(item)
        types = [
            "NxAnniversary",
            "TxTimeCommitment",
            "Wave",
            "TxDated",
            "NxTask"
        ]
        types.include?(item["mikuType"])
    end

    # Iam::isNyxNetworkItem(item)
    def self.isNyxNetworkItem(item)
        types = [
    # self contained
            "DxLine",
            "DxAionPoint",
            "DxFile",
            "DxText",
            "DxUniqueString",
            "DxUrl",
            "NxEvent",
            "NxCollection",
            "NxConcept",
            "NxEntity",
            "NxPerson",
            "NxTimeline",
        ]
        types.include?(item["mikuType"])
    end
end
