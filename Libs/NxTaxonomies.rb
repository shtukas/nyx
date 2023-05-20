class NxTaxonomies

    # NxTaxonomies::nxTaxonomies()
    def self.nxTaxonomies()
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
            "Pascal Pascal Explains",
            "Interesting",
            "Personal Diary",
            "Review"
        ]
    end

    # NxTaxonomies::selectOneTaxonomyOrNull()
    def self.selectOneTaxonomyOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("taxonomy", NxTaxonomies::nxTaxonomies())
    end
end