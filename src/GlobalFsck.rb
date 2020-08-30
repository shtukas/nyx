
# encoding: UTF-8

class GlobalFsck

    # GlobalFsck::main(runhash)
    def self.main(runhash)
        NyxFileSystemElementsMapping::fsck()
        NyxFsck::main(runhash)
    end
end