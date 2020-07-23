
# encoding: UTF-8

=begin

    The notion of realm was introduced to let Catalyst and DocNet to access different DataStore

    Essentially:

        Catalyst expects:
            - the primary data store in ~/DataBank/Catalyst/Nyx/
            - the desk in               ~/.catalyst/001-desk-85d03ad6-ba18-4b01-b9e3-8496eaab477f

        DocNet expects:
            - the primary data store in ~/.docnet/002-primary-store-949658fc-5474-45cf-b754-ab2500a89a93
            - the desk in               ~/.docnet/003-desk-44f9be8d-b2c0-4ae5-a182-a4115928b094

    When the program starts
        - We first check that "exitIfNotExist" elements are all there otherwise we exit
        - We check the "createIfNotExist" elements and create the missing ones
        - 

=end 

class Realms

    # Realms::getRealmConfig()
    def self.getRealmConfig()
        if ProgramVariant::id() == "catalyst" then
            return {
                "realmName" => "catalyst",
                "exitIfNotExist" => [
                    "#{ENV['HOME']}/Galaxy/DataBank/Catalyst/Nyx"
                ],
                "createIfNotExist" =>[
                    "#{ENV['HOME']}/.catalyst",
                    "#{ENV['HOME']}/.catalyst/001-desk-85d03ad6-ba18-4b01-b9e3-8496eaab477f"
                ],
                "primaryDataStoreFolderPath" => "#{ENV['HOME']}/Galaxy/DataBank/Catalyst/Nyx",
                "personalSpaceFolderPath" => "#{ENV['HOME']}/.catalyst"
            }
        end
        if ProgramVariant::id() == "docnet" then
            return {
                "realmName" => "docnet",
                "exitIfNotExist" => [

                ],
                "createIfNotExist" =>[
                    "#{ENV['HOME']}/.docnet",
                    "#{ENV['HOME']}/.docnet/002-primary-store-949658fc-5474-45cf-b754-ab2500a89a93",
                    "#{ENV['HOME']}/.docnet/003-desk-44f9be8d-b2c0-4ae5-a182-a4115928b094"
                ],
                "primaryDataStoreFolderPath" => "#{ENV['HOME']}/.docnet/002-primary-store-949658fc-5474-45cf-b754-ab2500a89a93",
                "personalSpaceFolderPath" => "#{ENV['HOME']}/.catalyst"
            }
        end
        raise "[error: 371ce8ea]"
    end

    # Realms::primaryDataStoreFolderPath()
    def self.primaryDataStoreFolderPath()
        Realms::getRealmConfig()["primaryDataStoreFolderPath"]
    end

    # Realms::personalSpaceFolderPath()
    def self.personalSpaceFolderPath()
        Realms::getRealmConfig()["personalSpaceFolderPath"]
    end

    # Realms::getDeskFolderpath()
    def self.getDeskFolderpath()
        "#{Realms::personalSpaceFolderPath()}/001-desk-85d03ad6-ba18-4b01-b9e3-8496eaab477f"
    end
end
