# encoding: UTF-8

class DisplayListingParameters

    # DisplayListingParameters::ns16sWithoutNx50s(domain)
    def self.ns16sWithoutNx50s(domain)

        ns16 = []

        if domain == "(eva)" then
            ns16 = [
                Anniversaries::ns16s(),
                Calendar::ns16s(),
                JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/amanda-bin-monitor`),
                JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Binaries/fitness ns16s`),
                DrivesBackups::ns16s(),
                Waves::ns16s(domain),
                Inbox::ns16s()
            ]
        end

        if domain == "(work)" then
            ns16 = [
                Waves::ns16s(domain),
            ]
        end

        if domain == "(jedi)" then
            ns16 = [
                Waves::ns16s(domain),
            ]
        end

        ns16
            .flatten
            .compact
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
            .select{|ns16| InternetStatus::ns16ShouldShow(ns16["uuid"]) }
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
        structure = Nx50s::structureForNathalie()
        {
            "domain"   => nil,
            "monitor"  => structure["Monitor"],
            "overflow" => structure["overflow"],
            "ns16s"    => ns16sPart1 + structure["Dated"] + structure["Tail"]
        }
    end
end
