
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

class GitRepository1SyncOperator

    # GitRepository1SyncOperator::pathToGithubRepository()
    def self.pathToGithubRepository()
        "#{Realms::gitDataRepositoryParentFolderpath()}/docnet-data-store-1"
    end

    # GitRepository1SyncOperator::doCloneRepository()
    def self.doCloneRepository()
        pathToScript = File.expand_path("#{File.dirname(__FILE__)}/../shell-scripts/001-clone-docnet-data-store-1")
        system(pathToScript)
    end

    # GitRepository1SyncOperator::cloneRepositoryIfNotDoneYet()
    def self.cloneRepositoryIfNotDoneYet()
        if !File.exists?(GitRepository1SyncOperator::pathToGithubRepository()) then
            GitRepository1SyncOperator::doCloneRepository()
        end
    end

    # GitRepository1SyncOperator::doPullRepositoryData()
    def self.doPullRepositoryData()
        pathToScript = File.expand_path("#{File.dirname(__FILE__)}/../shell-scripts/002-pull")
        system(pathToScript)
    end

    # GitRepository1SyncOperator::doPushRepositoryData()
    def self.doPushRepositoryData()
        pathToScript = File.expand_path("#{File.dirname(__FILE__)}/../shell-scripts/003-push")
        system(pathToScript)
    end

    # GitRepository1SyncOperator::doSynchronizeRepositoryData()
    def self.doSynchronizeRepositoryData()
        GitRepository1SyncOperator::doPullRepositoryData()
        GitRepository1SyncOperator::doPushRepositoryData()
    end
end
