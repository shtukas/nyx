
# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

DISPLAY_DOMAINS_DATA_FILEPATH = "/Galaxy/DataBank/Catalyst/DisplayDomains/display-domain-data.json"

$DisplayDomainInMemoryData = JSON.parse(IO.read(DISPLAY_DOMAINS_DATA_FILEPATH))

class NSXDisplayDomains 

    # -----------------------------------------------
    # Setters

    # NSXDisplayDomains::commitInMemoryDataToDisk()
    def self.commitInMemoryDataToDisk()
        File.open(DISPLAY_DOMAINS_DATA_FILEPATH, "w"){|f| f.puts(JSON.pretty_generate($DisplayDomainInMemoryData)) }
    end

    # NSXDisplayDomains::registerClaim(objectuuid, domainname)
    def self.registerClaim(objectuuid, domainname)
        claim = {
            "claimtime"  => Time.new.to_i,
            "objectuuid" => objectuuid,
            "domainname" => domainname
        }
        $DisplayDomainInMemoryData["claims"][objectuuid] = claim
        NSXDisplayDomains::commitInMemoryDataToDisk()
        claim
    end

    # NSXDisplayDomains::setNewActiveDomain(domainname)
    def self.setNewActiveDomain(domainname)
        $DisplayDomainInMemoryData["active-domain"] = domainname
        NSXDisplayDomains::commitInMemoryDataToDisk()
        NSXDisplayDomains::setDomainActivationTime(domainname)
    end

    # NSXDisplayDomains::setNewActiveDomainToNothing()
    def self.setNewActiveDomainToNothing()
        $DisplayDomainInMemoryData["active-domain"] = nil
        NSXDisplayDomains::commitInMemoryDataToDisk()
    end

    # NSXDisplayDomains::discardClaimAgainstObjectuui(objectuuid)
    def self.discardClaimAgainstObjectuui(objectuuid)
        $DisplayDomainInMemoryData["claims"].delete(objectuuid)
        NSXDisplayDomains::commitInMemoryDataToDisk()
    end

    # -----------------------------------------------
    # Getters

    # NSXDisplayDomains::domains()
    def self.domains()
        $DisplayDomainInMemoryData["claims"]
            .values
            .map{|claim| claim["domainname"] }
            .uniq
    end

    # NSXDisplayDomains::objectuuids()
    def self.objectuuids()
        $DisplayDomainInMemoryData["claims"].values
            .map{|claim| claim["objectuuid"] }.uniq
    end

    # NSXDisplayDomains::objectuuidsForDomain(domainname)
    def self.objectuuidsForDomain(domainname)
        $DisplayDomainInMemoryData["claims"].values
            .select{|claim| claim["domainname"]==domainname }
            .map{|claim| claim["objectuuid"] }.uniq
    end

    # NSXDisplayDomains::activeDomains()
    def self.activeDomainOrNull()
        $DisplayDomainInMemoryData["active-domain"]
    end

    # NSXDisplayDomains::objectuuidIsAgainstAClaim(objectuuid)
    def self.objectuuidIsAgainstAClaim(objectuuid)
        NSXDisplayDomains::objectuuids().include?(objectuuid)
    end

    # -----------------------------------------------
    # Special Circumstances

    # NSXDisplayDomains::setDomainActivationTime(domainname)
    def self.setDomainActivationTime(domainname)
        KeyValueStore::set(nil, "1dfabe77-7cee-4944-aab8-a08979030753:#{domainname}", Time.new.to_i)
    end

    # NSXDisplayDomains::getDomainLastActivationTime(domainname)
    def self.getDomainLastActivationTime(domainname)
        KeyValueStore::getOrDefaultValue(nil, "1dfabe77-7cee-4944-aab8-a08979030753:#{domainname}", "0").to_i
    end

    # NSXDisplayDomains::domainIsDueForReview(domainname)
    def self.domainIsDueForReview(domainname)
        (Time.new.to_i - NSXDisplayDomains::getDomainLastActivationTime(domainname)) > 86400
    end

    # NSXDisplayDomains::getDisplayDomainDueForReviewOrNull()
    def self.getDisplayDomainDueForReviewOrNull()
        NSXDisplayDomains::domains()
            .select{|domainname| NSXDisplayDomains::domainIsDueForReview(domainname) }
            .first
    end

    # -----------------------------------------------
    # User Interface Support

    # NSXDisplayDomains::interactivelySelectOneExistingDomainsOrNull()
    def self.interactivelySelectOneExistingDomainsOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("domain:", NSXDisplayDomains::domains())
    end

    # NSXDisplayDomains::interactivelySelectDomainPossiblyNewOrNull()
    def self.interactivelySelectDomainPossiblyNewOrNull()
        domainFromExisting = NSXDisplayDomains::interactivelySelectOneExistingDomainsOrNull()
        return domainFromExisting if domainFromExisting
        domain = LucilleCore::askQuestionAnswerAsString("domain (empty for null): ")
        domain.size>0 ? domain : nil
    end

end



