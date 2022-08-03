class StargateCentral

    # StargateCentral::pathToCentral()
    def self.pathToCentral()
        "/Volumes/Infinity/Data/Pascal/Galaxy/Stargate-Central"
    end

    # StargateCentral::isVisible()
    def self.isVisible()
        File.exists?(StargateCentral::pathToCentral())
    end

    # StargateCentral::ensureInfinityDrive()
    def self.ensureInfinityDrive()
        return if File.exists?(StargateCentral::pathToCentral())
        puts "I need the Infinity drive, please plug".green
        LucilleCore::pressEnterToContinue()
        return if File.exists?(StargateCentral::pathToCentral())
        puts "Could not find the Infinity drive. Exiting."
        exit 1
    end
end
