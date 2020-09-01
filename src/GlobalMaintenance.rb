
# encoding: UTF-8

class GlobalMaintenance

    # GlobalMaintenance::main()
    def self.main()
        NyxGarbageCollection::run()
        SelectionLookupDataset::rebuildDataset()
        DatapointNyxElementLocation::automaintenance(true)
    end
end