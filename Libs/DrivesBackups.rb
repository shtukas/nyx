
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

    # DrivesBackups::instructionToString(instruction)
    def self.instructionToString(instruction)
        "[bckp] [backup] (auto done) #{instruction["description"]}"
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
                    "announce"    => DrivesBackups::instructionToString(instruction),
                }
            }
    end

    # DrivesBackups::nx19s()
    def self.nx19s()
        DrivesBackups::instructions()
            .map{|instruction|
                {
                    "uuid"     => instruction["uuid"],
                    "announce" => DrivesBackups::instructionToString(instruction),
                    "lambda"   => lambda {}
                }
            }
    end

end