
# encoding: UTF-8

class Listings

    # Listings::makeNewListingOrNull()
    def self.makeNewListingOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["operational listing", "encyclopedia listing"])
        if type == "operational listing" then
            return OperationalListings::issueListingInteractivelyOrNull()
        end
        if type == "encyclopedia listing" then
            return EncyclopediaListings::issueKnowledgeNodeInteractivelyOrNull()
        end
        nil
    end

    # Listings::setListingName(listing, name_)
    def self.setListingName(listing, name_)
        if GenericNyxObject::isOperationalListing(listing) then
            listing["name"] = name_
            NyxObjects2::put(listing)
            return nil
        end
        if GenericNyxObject::isEncyclopediaListing(listing) then
            listing["name"] = name_
            NyxObjects2::put(listing)
            return nil
        end
        puts listing
        raise "error: db35548c-310b-485e-8ce0-2af23a93d02e"
    end

    # Listings::searchAndReturnListingOrNullIntellisense()
    def self.searchAndReturnListingOrNullIntellisense()
        # lambda1: pattern: String -> Array[String]
        # lambda2: string:  String -> Object or null

        #{
        #    "objecttype"
        #    "objectuuid"
        #    "fragment"
        #    "object"
        #    "referenceunixtime"
        #}

        lambda1 = lambda { |pattern|
            Patricia::patternToOrderedSearchResults(pattern)
                .select{|item| GenericNyxObject::isGenericListing(item["object"]) }
                .map{|item| item["fragment"] }
        }

        lambda2 = lambda { |fragment|
            Patricia::patternToOrderedSearchResults(fragment)
                .select{|item| item["fragment"] == fragment }
                .map{|item| item["object"] }
                .first
        }

        Miscellaneous::ncurseSelection1410(lambda1, lambda2)
    end

    # Listings::extractionSelectListingOrMakeListingOrNull()
    def self.extractionSelectListingOrMakeListingOrNull()
        operations = ["select listing", "make listing", "return null"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
        return nil if operation.nil?
        if operation == "select listing" then
            listing = Listings::searchAndReturnListingOrNullIntellisense()
            if listing then
                return listing
            end
        end
        if operation == "make listing" then
            listing = Listings::makeNewListingOrNull()
            if listing then
                return listing
            end
        end
        if operation == "return null" then
            return nil
        end
    end
end