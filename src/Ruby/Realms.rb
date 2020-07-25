
# encoding: UTF-8

class Realms

    # Realms::getRealmConfig()
    def self.getRealmConfig()
        if ProgramVariant::id() == "catalyst" then
            return {
                "realmName" => "catalyst",
                "realmUniqueId" => "9bb04774-20cc-4a65-808b-169379381729",
                "exitIfNotExist" => [
                    "#{ENV['HOME']}/Galaxy/DataBank/Catalyst/Nyx"
                ],
                "createIfNotExist" =>[
                    "#{ENV['HOME']}/.catalyst",
                    "#{ENV['HOME']}/.catalyst/001-desk-85d03ad6-ba18-4b01-b9e3-8496eaab477f",
                    "#{ENV['HOME']}/.catalyst/004-key-value-store-999a28e2-9d55-4f93-8a99-5e026512f43c",
                    "#{ENV['HOME']}/.catalyst/005-git-data-repository-a7da89f5-0a4a-4af0-92fc-6e150ac10e5c"
                ],
                "primaryDataStoreFolderPath" => "#{ENV['HOME']}/Galaxy/DataBank/Catalyst/Nyx",
                "personalSpaceFolderPath" => "#{ENV['HOME']}/.catalyst"
            }
        end
        if ProgramVariant::id() == "docnet" then
            return {
                "realmName" => "docnet",
                "realmUniqueId" => "daf00c4b-7530-4462-b043-153a03625eed",
                "exitIfNotExist" => [

                ],
                "createIfNotExist" =>[
                    "#{ENV['HOME']}/.docnet",
                    "#{ENV['HOME']}/.docnet/001-desk-85d03ad6-ba18-4b01-b9e3-8496eaab477f",
                    "#{ENV['HOME']}/.docnet/002-primary-store-949658fc-5474-45cf-b754-ab2500a89a93",
                    "#{ENV['HOME']}/.docnet/002-primary-store-949658fc-5474-45cf-b754-ab2500a89a93/Nyx",
                    "#{ENV['HOME']}/.docnet/002-primary-store-949658fc-5474-45cf-b754-ab2500a89a93/Nyx/Nyx-Blobs",
                    "#{ENV['HOME']}/.docnet/002-primary-store-949658fc-5474-45cf-b754-ab2500a89a93/Nyx/Nyx-Objects",
                    "#{ENV['HOME']}/.docnet/004-key-value-store-999a28e2-9d55-4f93-8a99-5e026512f43c",
                    "#{ENV['HOME']}/.docnet/005-git-data-repository-a7da89f5-0a4a-4af0-92fc-6e150ac10e5c",
                ],
                "primaryDataStoreFolderPath" => "#{ENV['HOME']}/.docnet/002-primary-store-949658fc-5474-45cf-b754-ab2500a89a93/Nyx",
                "personalSpaceFolderPath" => "#{ENV['HOME']}/.docnet"
            }
        end
        raise "[error: 371ce8ea]"
    end

    # Realms::getRealmName()
    def self.getRealmName()
        Realms::getRealmConfig()["realmName"]
    end

    # Realms::isCatalyst()
    def self.isCatalyst()
        Realms::getRealmName() == "catalyst"
    end

    # Realms::isDocnet()
    def self.isDocnet()
        Realms::getRealmName() == "docnet"
    end

    # Realms::isDocnetAlexandra()
    def self.isDocnetAlexandra()
        Realms::isDocnet() and Miscellaneous::isAlexandra()
    end

    # Realms::isDocnetNonAlexandra()
    def self.isDocnetNonAlexandra()
        Realms::isDocnet() and !Miscellaneous::isAlexandra()
    end

    # Realms::raiseException()
    def self.raiseException()
        raise "[error: ce2d77de-504c-4a05-80a6-ea2c851131e3]"
    end

    # Realms::getRealmUniqueId()
    def self.getRealmUniqueId()
        Realms::getRealmConfig()["realmUniqueId"]
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

    # Realms::getKeyValueStoreFolderpath()
    def self.getKeyValueStoreFolderpath()
        "#{Realms::personalSpaceFolderPath()}/004-key-value-store-999a28e2-9d55-4f93-8a99-5e026512f43c"
    end

    # Realms::gitHubDataRepositoryParentFolderpath()
    def self.gitHubDataRepositoryParentFolderpath()
        "#{Realms::personalSpaceFolderPath()}/005-git-data-repository-a7da89f5-0a4a-4af0-92fc-6e150ac10e5c"
    end

    # Realms::pathToGitHubRepositoryDataStore1()
    def self.pathToGitHubRepositoryDataStore1()
        "#{Realms::gitHubDataRepositoryParentFolderpath()}/docnet-data-store-1"
    end
end
