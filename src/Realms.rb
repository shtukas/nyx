
# encoding: UTF-8

class Realms

    # Realms::getRealmConfig()
    def self.getRealmConfig()
        {
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

    # Realms::pathToDataStore3()
    def self.pathToDataStore3()
        "#{Realms::gitHubDataRepositoryParentFolderpath()}/docnet-data-store-1"
    end
end
