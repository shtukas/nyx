
class PolyActions

    # function name alphabetical order

    # PolyActions::access(item)
    def self.access(item)

        if item["mikuType"] == "fitness1" then
            puts PolyFunctions::toString(item).green
            system("#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness doing #{item["fitness-domain"]}")
            SystemEvents::process({
                "mikuType"   => "(object has been touched)",
                "objectuuid" => item["uuid"]
            })
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::access(item)
            SystemEvents::process({
                "mikuType"   => "(object has been touched)",
                "objectuuid" => item["uuid"]
            })
            return
        end

        if item["mikuType"] == "NxBall.v2" then
            if NxBallsService::isRunning(item["uuid"]) then
                if LucilleCore::askQuestionAnswerAsBoolean("complete '#{PolyFunctions::toString(item).green}' ? ") then
                    NxBallsService::close(item["uuid"], true)
                end
            end
            return
        end

        if item["mikuType"] == "NyxNode" then
            NyxNodes::access(item)
            SystemEvents::process({
                "mikuType"   => "(object has been touched)",
                "objectuuid" => item["uuid"]
            })
            return
        end

        if item["mikuType"] == "NxTodo" then
            NxTodos::access(item)
            SystemEvents::process({
                "mikuType"   => "(object has been touched)",
                "objectuuid" => item["uuid"]
            })
            return
        end

        if item["mikuType"] == "Wave" then
            puts Waves::toString(item).green
            Waves::access(item)
            SystemEvents::process({
                "mikuType"   => "(object has been touched)",
                "objectuuid" => item["uuid"]
            })
            return
        end

        raise "(error: abb645e9-2575-458e-b505-f9c029f4ca69) I do not know how to access mikuType: #{item["mikuType"]}"
    end

    # PolyActions::destroyWithPrompt(item)
    def self.destroyWithPrompt(item)
        PolyActions::stop(item)
        if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction of #{item["mikuType"]} '#{PolyFunctions::toString(item).green}' ") then
            NxDeleted::deleteObject(item["uuid"])
        end
    end

    # PolyActions::doubleDot(item)
    def self.doubleDot(item)

        puts "PolyActions::doubleDot(#{JSON.pretty_generate(item)})"

        if item["mikuType"] == "fitness1" then
            PolyActions::access(item)
            SystemEvents::process({
                "mikuType"   => "(object has been touched)",
                "objectuuid" => item["uuid"]
            })
            return
        end

        if item["mikuType"] == "TxDated" then
            PolyActions::start(item)
            PolyActions::access(item)
            loop {
                actions = ["keep running and back to listing", "stop and back to listing", "stop and destroy"]
                action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", actions)
                next if action.nil?
                if action == "keep running and back to listing" then
                    SystemEvents::process({
                        "mikuType"   => "(object has been touched)",
                        "objectuuid" => item["uuid"]
                    })
                    return
                end
                if action == "stop and back to listing" then
                    PolyActions::stop(item)
                    SystemEvents::process({
                        "mikuType"   => "(object has been touched)",
                        "objectuuid" => item["uuid"]
                    })
                    return
                end
                if action == "stop and destroy" then
                    PolyActions::stop(item)
                    PolyActions::destroyWithPrompt(item)
                    SystemEvents::process({
                        "mikuType"   => "(object has been touched)",
                        "objectuuid" => item["uuid"]
                    })
                    return
                end
            }
            SystemEvents::process({
                "mikuType"   => "(object has been touched)",
                "objectuuid" => item["uuid"]
            })
            return
        end

        if item["mikuType"] == "Wave" then
            PolyActions::start(item)
            PolyActions::access(item)
            if LucilleCore::askQuestionAnswerAsBoolean("done '#{PolyFunctions::toString(item).green}' ? ") then
                Waves::performWaveNx46WaveDone(item)
                PolyActions::stop(item)
                SystemEvents::process({
                    "mikuType"   => "(object has been touched)",
                    "objectuuid" => item["uuid"]
                })
            else
                if LucilleCore::askQuestionAnswerAsBoolean("continue ? ") then
                    return
                else
                    PolyActions::stop(item)
                    SystemEvents::process({
                        "mikuType"   => "(object has been touched)",
                        "objectuuid" => item["uuid"]
                    })
                end
            end
            return
        end

        PolyActions::start(item)
        PolyActions::access(item)
        SystemEvents::process({
            "mikuType"   => "(object has been touched)",
            "objectuuid" => item["uuid"]
        })
    end

    # PolyActions::done(item)
    def self.done(item)

        PolyActions::stop(item)

        SystemEvents::process({
            "mikuType"   => "(object has been touched)",
            "objectuuid" => item["uuid"]
        })

        # order: alphabetical order

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::done(item["uuid"])
            SystemEvents::process({
                "mikuType"   => "(object has been touched)",
                "objectuuid" => item["uuid"]
            })
            return
        end

        if item["mikuType"] == "NxBall.v2" then
            return
        end

        if item["mikuType"] == "NxTodo" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy NxTodo '#{item["description"].green}' ? ", true) then
                NxTodos::destroy(item["uuid"])
            end
            SystemEvents::process({
                "mikuType"   => "(object has been touched)",
                "objectuuid" => item["uuid"]
            })
            return
        end

        if item["mikuType"] == "Wave" then
            if LucilleCore::askQuestionAnswerAsBoolean("done-ing '#{Waves::toString(item).green} ? '", true) then
                Waves::performWaveNx46WaveDone(item)
            end
            SystemEvents::process({
                "mikuType"   => "(object has been touched)",
                "objectuuid" => item["uuid"]
            })
            return
        end

        puts "I do not know how to PolyActions::done(#{JSON.pretty_generate(item)})"
        raise "(error: f278f3e4-3f49-4f79-89d2-e5d3b8f728e6)"
    end

    # PolyActions::editDatetime(item)
    def self.editDatetime(item)
        datetime = CommonUtils::editTextSynchronously(item["datetime"]).strip
        return if !CommonUtils::isDateTime_UTC_ISO8601(datetime)
        ItemsEventsLog::setAttribute2(item["uuid"], "datetime", datetime)
        SystemEvents::process({
            "mikuType"   => "(object has been touched)",
            "objectuuid" => item["uuid"]
        })
    end

    # PolyActions::editDescription(item)
    def self.editDescription(item)
        description = CommonUtils::editTextSynchronously(item["description"]).strip
        return if description == ""
        ItemsEventsLog::setAttribute2(item["uuid"], "description", description)
        SystemEvents::process({
            "mikuType"   => "(object has been touched)",
            "objectuuid" => item["uuid"]
        })
    end

    # PolyActions::editStartDate(item)
    def self.editStartDate(item)
        if item["mikuType"] != "NxAnniversary" then
            puts "update description is only implemented for NxAnniversary"
            LucilleCore::pressEnterToContinue()
            return
        end

        startdate = CommonUtils::editTextSynchronously(item["startdate"])
        return if startdate == ""
        ItemsEventsLog::setAttribute2(item["uuid"], "startdate",   startdate)

        SystemEvents::process({
            "mikuType"   => "(object has been touched)",
            "objectuuid" => item["uuid"]
        })
    end

    # PolyActions::garbageCollectionAsPartOfLaterItemDestruction(item)
    def self.garbageCollectionAsPartOfLaterItemDestruction(item)
        return if item.nil?

        # order : alphabetical order
    end

    # PolyActions::redate(item)
    def self.redate(item)
        if item["mikuType"] != "NxTodo" then
            puts "redate only applies to NxTodos (engine: ondate)"
            LucilleCore::pressEnterToContinue()
            return
        end
        if item["nx11e"]["type"] != "ondate" then
            puts "redate only applies to NxTodos (engine: ondate)"
            LucilleCore::pressEnterToContinue()
            return
        end
        datetime = CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
        ItemsEventsLog::setAttribute2(item["uuid"], "nx11e", Nx11E::makeOndate(datetime))

        SystemEvents::process({
            "mikuType"   => "(object has been touched)",
            "objectuuid" => item["uuid"]
        })
    end

    # PolyActions::setNx113(item)
    def self.setNx113(item)
        nx113nhash = Nx113Make::interactivelyIssueNewNx113OrNullReturnDataBase1Nhash()
        return if nx113nhash.nil?
        ItemsEventsLog::setAttribute2(item["uuid"], "nx113", nx113nhash)

        SystemEvents::process({
            "mikuType"   => "(object has been touched)",
            "objectuuid" => item["uuid"]
        })
    end

    # PolyActions::start(item)
    def self.start(item)
        #puts "PolyActions::start(#{JSON.pretty_generate(item)})"
        return if NxBallsService::isRunning(item["uuid"])
        accounts = []
        accounts << item["uuid"]
        if item["mikuType"] == "NxTodo" then
            nx11e = item["nx11e"]
            if nx11e["type"] == "Ax39Group" then
                accounts << nx11e["group"]["account"] # We also register the group account
            end
            if nx11e["type"] == "Ax39Engine" then
                # There is a itemuuid here, but it is the same as the item["uuid"] itself
            end
        end
        NxBallsService::issue(item["uuid"], PolyFunctions::toString(item), accounts, PolyFunctions::timeBeforeNotificationsInHours(item)*3600)

        SystemEvents::process({
            "mikuType"   => "(object has been touched)",
            "objectuuid" => item["uuid"]
        })
    end

    # PolyActions::stop(item)
    def self.stop(item)
        #puts "PolyActions::stop(#{JSON.pretty_generate(item)})"
        NxBallsService::close(item["uuid"], true)

        SystemEvents::process({
            "mikuType"   => "(object has been touched)",
            "objectuuid" => item["uuid"]
        })
    end

    # PolyActions::transmute(item)
    def self.transmute(item)
        interactivelyChooseMikuTypeOrNull = lambda{|mikuTypes|
            LucilleCore::selectEntityFromListOfEntitiesOrNull("mikuType", mikuTypes)
        }

        SystemEvents::process({
            "mikuType"   => "(object has been touched)",
            "objectuuid" => item["uuid"]
        })
    end
end
