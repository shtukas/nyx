
# encoding: UTF-8

class DrivesBackups

    # DrivesBackups::getLastBackupUnixtime(filepath)
    def self.getLastBackupUnixtime(filepath)
        return 0 if !File.exists?(filepath)
        IO.read(filepath).to_i
    end

    # DrivesBackups::instructions()
    def self.instructions()
        JSON.parse(IO.read("/Users/pascal/Galaxy/DataBank/Catalyst/Drives-Backups/instructions.json"))
    end

    # DrivesBackups::ns16s()
    def self.ns16s()
        DrivesBackups::instructions()
            .select{|instruction|
                Time.new.to_i - DrivesBackups::getLastBackupUnixtime(instruction["filepath"]) > instruction["periodInDays"]*86400
            }
            .map{|instruction|
                {
                    "uuid"        => instruction["uuid"],
                    "announce"    => "[bckp] #{instruction["description"]} (auto done)",
                    "commands"    => nil,
                    "interpreter" => nil
                }
            }
    end
end