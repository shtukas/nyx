
# encoding: UTF-8

=begin

echo "# docnet-data-store-1" >> README.md
git init
git add README.md
git commit -m "first commit"
git remote add origin https://github.com/shtukas/docnet-data-store-1.git
git push -u origin master

https://github.com/shtukas/docnet-data-store-1

=end

class DataStore3RemoteControl

    # DataStore3RemoteControl::doCloneRepository()
    def self.doCloneRepository()
        pathToScript = File.expand_path("#{File.dirname(__FILE__)}/../shell-scripts/001-clone-docnet-data-store-1")
        system(pathToScript)
    end

    # DataStore3RemoteControl::cloneRepositoryIfNotDoneYet()
    def self.cloneRepositoryIfNotDoneYet()
        if !File.exists?(Realms::pathToGitHubRepositoryDataStore1()) then
            DataStore3RemoteControl::doCloneRepository()
        end
    end

    # DataStore3RemoteControl::doPullRepositoryData()
    def self.doPullRepositoryData()
        DataStore3RemoteControl::cloneRepositoryIfNotDoneYet()
        pathToScript = File.expand_path("#{File.dirname(__FILE__)}/../shell-scripts/002-pull")
        system(pathToScript)
    end

    # DataStore3RemoteControl::doPushRepositoryData()
    def self.doPushRepositoryData()
        DataStore3RemoteControl::cloneRepositoryIfNotDoneYet()
        pathToScript = File.expand_path("#{File.dirname(__FILE__)}/../shell-scripts/003-push")
        system(pathToScript)
    end

    # DataStore3RemoteControl::doSynchronizeRepositoryData()
    def self.doSynchronizeRepositoryData()
        DataStore3RemoteControl::doPullRepositoryData()
        DataStore3RemoteControl::doPushRepositoryData()
    end
end
