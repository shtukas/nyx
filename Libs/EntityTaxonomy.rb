
# encoding: UTF-8

class EntityTaxonomy

    # EntityTaxonomy::taxonomies()
    def self.taxonomies()
        [
            "TxUndefined",         # Default for backward compatibility
            "TxPersonalDiary",
            "TxPersonalCalendar",
            "TxPersonalEvent",
            "TxTravelAndEntertainmentDocuments",
            "TxPublicEvent",
            "TxInformation",
            "TxExplanation",
            "TxFunny",
            "TxInteresting",       # Subset of TxInformation
            "TxMedia"
        ]
    end

    # EntityTaxonomy::selectEntityTaxonomyOrNull()
    def self.selectEntityTaxonomyOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("node taxonomy:", EntityTaxonomy::taxonomies())
    end

    # EntityTaxonomy::selectEntityTaxonomyUseDefaultIfNull()
    def self.selectEntityTaxonomyUseDefaultIfNull()
        EntityTaxonomy::selectEntityTaxonomyOrNull() || "TxUndefined"
    end
end
