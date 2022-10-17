
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

                PhagePublic::mikuTypeToObjects("NxBall.v2").each{|nxball|
                    NxBallsService::marginCallIfIsTime(nxball)
                }

                PhagePublic::mikuTypeToObjects("NxBall.v2").each{|nxball|
                    next if nxball["status"]["type"] != "running"
                    timespan = Time.new.to_f - nxball["status"]["thisSprintStartUnixtime"]
                    if timespan > nxball["desiredBankedTimeInSeconds"] then
                        CommonUtils::onScreenNotification("Catalyst", "NxBall over running")
                    end
                }
                
            }
        }
    end
end
