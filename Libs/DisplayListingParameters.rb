# encoding: UTF-8

class DisplayListingParameters

    # DisplayListingParameters::ns16sWithoutNx50s(domain)
    def self.ns16sWithoutNx50s(domain)
        [
            Anniversaries::ns16s(),
            Calendar::ns16s(),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/amanda-bin-monitor`),
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
            DrivesBackups::ns16s(),
            Waves::ns16s(domain),
            Inbox::ns16s()
        ]
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
    end

    # DisplayListingParameters::removeDuplicates(ns16s)
    def self.removeDuplicates(ns16s)
        ns16s.reduce([]){|elements, ns16|
            if elements.none?{|x| x["uuid"] == ns16["uuid"]} then
                elements << ns16
            end
            elements
        }
    end

    # DisplayListingParameters::getListingParametersForDomain(domain)
    def self.getListingParametersForDomain(domain)
        ns16sPart1 = DisplayListingParameters::ns16sWithoutNx50s(domain)
        structure = Nx50s::structureForDomain(domain)
        {
            "domain"   => domain,
            "monitor"  => structure["Monitor"],
            "overflow" => structure["overflow"],
            "ns16s"    => ns16sPart1 + structure["Dated"] + structure["Tail"]
        }
    end

    # DisplayListingParameters::getNathalieListingParameters()
    def self.getNathalieListingParameters()
        ns16sPart1 = Domain::domains().map{|domain| DisplayListingParameters::ns16sWithoutNx50s(domain) }.flatten
        ns16sPart1 = DisplayListingParameters::removeDuplicates(ns16sPart1)
        structure = Nx50s::structureForNathalie()
        {
            "domain"   => nil,
            "monitor"  => structure["Monitor"],
            "overflow" => structure["overflow"],
            "ns16s"    => (ns16sPart1 + structure["Dated"] + structure["Tail"]).shuffle
        }
    end
end
