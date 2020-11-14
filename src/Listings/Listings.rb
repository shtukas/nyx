
# encoding: UTF-8

class Listings

    # Listings::makeNewListingOrNull()
    def self.makeNewListingOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["operational listing", "encyclopedia listing"])
        if type == "operational listing" then
            return OperationalListings::issueListingInteractivelyOrNull()
        end
        if type == "encyclopedia listing" then
            return EncyclopediaListings::issueListingInteractivelyOrNull()
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

    # Listings::selectSelfOrDescendantOrNull(object)
    def self.selectSelfOrDescendantOrNull(object)
        loop {
            puts ""
            puts "object: #{GenericNyxObject::toString(object)}"
            puts "targets:"
            Arrows::getTargetsForSource(object).each{|target|
                puts "    #{GenericNyxObject::toString(target)}"
            }
            operations = ["return object", "select and return one target", "select and focus on target", "return null"]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return nil if operation.nil?
            if operation == "return object" then
                return object
            end
            if operation == "select and return one target" then
                t = GenericNyxObject::selectOneTargetOrNullDefaultToSingletonWithConfirmation(object)
                if t then
                    return t
                end
            end
            if operation == "select and focus on target" then
                t =  GenericNyxObject::selectOneTargetOrNullDefaultToSingletonWithConfirmation(object)
                if t then
                    return Listings::selectSelfOrDescendantOrNull(t)
                end
            end
            if operation == "return null" then
                return nil
            end
        }
    end

    # Listings::extractionSelectListingOrMakeListingOrNull()
    def self.extractionSelectListingOrMakeListingOrNull()
        loop {
            puts ""
            operations = ["select listing", "make listing", "return null"]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return nil if operation.nil?
            if operation == "select listing" then
                listing = Listings::searchAndReturnListingOrNullIntellisense()
                if listing then
                    puts "selected: #{GenericNyxObject::toString(listing)}"
                    operations = ["return listing", "landing then return listing", "select listing descendant"]
                    operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
                    next if operation.nil?
                    if operation == "return listing" then
                        return listing
                    end
                    if operation == "landing then return listing" then
                        GenericNyxObject::landing(listing)
                        listing = NyxObjects2::getOrNull(listing["uuid"])
                        next if listing.nil?
                        return listing
                    end
                    if operation == "select listing descendant" then
                        d = Listings::selectSelfOrDescendantOrNull(listing)
                        return d if d
                    end
                end
            end
            if operation == "make listing" then
                listing = Listings::makeNewListingOrNull()
                if listing then
                    puts "made: #{GenericNyxObject::toString(listing)}"
                    if LucilleCore::askQuestionAnswerAsBoolean("Landing before returning ? ") then
                        GenericNyxObject::landing(listing)
                        listing = NyxObjects2::getOrNull(listing["uuid"])
                    end
                    next if listing.nil?
                    return listing
                end
            end
            if operation == "return null" then
                return nil
            end
        }
    end
end