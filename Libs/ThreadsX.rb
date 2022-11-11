
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

                NxBallsService::items().each{|nxball|
                    if (Time.new.to_f - nxball["start"]) > 3600 then
                        CommonUtils::onScreenNotification("Catalyst", "NxBall over running")
                    end
                }
                
            }
        }
    end
end
