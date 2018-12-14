
# encoding: UTF-8

def catalyst_folderpath_2d2cda3e()
    if ENV["COMPUTERLUCILLENAME"] == "Lucille18" then
        "/Galaxy/DataBank/Catalyst"
    else
        remotePath = "/Volumes/Lucille18/Galaxy/DataBank/Catalyst"
        if File.exists?(remotePath) then
            remotePath
        else
            raise "Cannot see #{remotePath}"
        end
    end
end

CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH = catalyst_folderpath_2d2cda3e()
CATALYST_COMMON_BIN_ARCHIVES_TIMELINE_FOLDERPATH = "#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Bin-Timeline"
