# encoding: UTF-8

class NyxGarbageCollection

    # NyxGarbageCollection::run()
    def self.run()
        
        puts "NyxGarbageCollection::run()"
        
        Arrows::arrows().each{|arrow|
            b1 = NyxPrimaryObjects::getOrNull(arrow["sourceuuid"]).nil?
            b2 = NyxPrimaryObjects::getOrNull(arrow["targetuuid"]).nil?
            isNotConnecting = (b1 or b2)
            if isNotConnecting then
                puts "removing arrow: #{arrow}"
                NyxObjects::destroy(arrow["uuid"])
            end
        }

        DescriptionZ::descriptionz().each{|descriptionz|
            next if Arrows::getSourcesForTarget(descriptionz).size > 0
            puts "removing descriptionz: #{descriptionz}"
            NyxObjects::destroy(descriptionz["uuid"])
        }

        DateTimeZ::datetimez().each{|datetimez|
            next if Arrows::getSourcesForTarget(datetimez).size > 0
            puts "removing datetimez: #{datetimez}"
            NyxObjects::destroy(datetimez["uuid"])
        }

        Tags::tags().each{|tag|
            next if Arrows::getSourcesForTarget(tag).size > 0
            puts "removing tag: #{tag}"
            NyxObjects::destroy(tag["uuid"])
        }

        Notes::notes().each{|note|
            next if Arrows::getSourcesForTarget(note).size > 0
            puts "removing note: #{note}"
            NyxObjects::destroy(note["uuid"])
        }

        Comments::comments().each{|comment|
            next if Arrows::getSourcesForTarget(comment).size > 0
            puts "removing comment: #{comment}"
            NyxObjects::destroy(comment["uuid"])
        }

    end
end
