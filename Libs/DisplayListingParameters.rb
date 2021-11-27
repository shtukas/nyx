# encoding: UTF-8

=begin

This class prepares the DisplayParameters used by the Display Operator.
It
    1. Computes the NS16s without the Nx50s (wihtout Dated and Tail)
    2. Computes the display parameters for domain listings
    3. Computes the display parameters for Nathalie. Nathalie only deals with a managed collection of NS16s. 
       When we display Nathalie We display the latest Nx50 Monitor and Overflow, not a cached version.

=end


class DisplayListingParameters

    # DisplayListingParameters::ns16sPart1(domain)
    def self.ns16sPart1(domain)
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
        ns16sPart1 = DisplayListingParameters::ns16sPart1(domain)
        structure = Nx50s::structureForDomain(domain)
        {
            "domain"   => domain,
            "Monitor"  => structure["Monitor"],
            "overflow" => structure["overflow"],
            "ns16s"    => ns16sPart1 + structure["Dated"] + structure["Tail"]
        }
    end

    # DisplayListingParameters::getNathalieListingParameters()
    def self.getNathalieListingParameters()
        ns16sPart1 = Domain::domains().map{|domain| DisplayListingParameters::ns16sPart1(domain) }.flatten
        ns16sPart1 = DisplayListingParameters::removeDuplicates(ns16sPart1)
        structure = Nathalie::structure()
        {
            "domain"   => nil,
            "Monitor"  => structure["Monitor"],
            "overflow" => structure["overflow"],
            "ns16s"    => ns16sPart1 + structure["Dated"] + structure["Tail"]
        }
    end
end
