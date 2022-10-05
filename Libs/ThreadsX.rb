
class ThreadsX

    # ThreadsX::startViennaImport()
    def self.startViennaImport()
        Thread.new {
            loop {
                sleep 600
                system("#{File.dirname(__FILE__)}/operations/vienna-import")
            }
        }
    end

    # ThreadsX::nxBallsMonitoringAndNotification()
    def self.nxBallsMonitoringAndNotification()
        Thread.new {
            loop {
                sleep 60

                NxBallsIO::nxballs().each{|nxball|
                    NxBallsService::marginCallIfIsTime(nxball["uuid"])
                }

                NxBallsIO::nxballs().each{|nxball|
                    next if nxball["status"]["type"] != "running"
                    timespan = Time.new.to_f - nxball["status"]["thisSprintStartUnixtime"]
                    if timespan > nxball["desiredBankedTimeInSeconds"] then
                        CommonUtils::onScreenNotification("Catalyst", "NxBall over running")
                    end
                }
                
            }
        }
    end

    # ThreadsX::moveCarefully()
    def self.moveCarefully()
        Thread.new {
            loop {
                sleep 10
                CommsLine::moveCarefully(false)
            }
        }
    end

end
