class NxTaxonomies

    # NxTaxonomies::NxTaxonomies()
    def self.NxTaxonomies()
        [
            "Person",
            "Geolocation",
            "Entity",
            "Documentation",
            "Concept",
            "Technology",
            "Organization",
            "Commercial Entity",
            "Event",
            "News (Image/Article/Video)",
            "Documentary",
            "Funny",
            "Quote",
            "Pascal Brain Dump",
            "Interesting",
            "Personal Diary"
        ]
    end

    # NxTaxonomies::selectOneTaxonomyOrNull()
    def self.selectOneTaxonomyOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("taxonomy", NxNodes::nxTaxonomies())
    end
end