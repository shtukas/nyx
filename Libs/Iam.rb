
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
end
