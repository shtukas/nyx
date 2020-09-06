
# encoding: UTF-8

class GlobalFsck

    # GlobalFsck::main(runhash)
    def self.main(runhash)
        status = NyxFileSystemElementsMapping::fsck()
        return false if !status
        status = NyxFsck::main(runhash)
        status
    end

    # GlobalFsck::quickPossiblySelfRepairedFsck(verbose)
    def self.quickPossiblySelfRepairedFsck(verbose)
        status = GlobalFsck::main("d9f083c6-b426-4031-83ca-47775e8ba9e2:#{Time.new.to_s[0, 10]}")
        return true if status
        NSDatapointNyxElementLocation::automaintenance(verbose)
        status = GlobalFsck::main("d9f083c6-b426-4031-83ca-47775e8ba9e2:#{Time.new.to_s[0, 10]}")
        status
    end

end