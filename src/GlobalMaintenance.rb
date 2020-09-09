
# encoding: UTF-8

class GlobalMaintenance

    # GlobalMaintenance::main(verbose)
    def self.main(verbose)
        NyxGarbageCollection::run(verbose)
        NSNode1638NyxElementLocation::automaintenance(verbose)
        SelectionLookupDataset::rebuildDataset(verbose)
    end
end