
# encoding: UTF-8

class ProgramNx

    # lambdaDisplay: () -> () # side effect: prints the data
    # lambdaHelpDisplay: () -> String
    # lambdaPromptInterpreter: (command: String) -> () # side effect, execute the command.
    # lambdaStillGoing: () -> Boolean
    # ProgramNx::Nx01(lambdaDisplay, lambdaHelpDisplay, lambdaPromptInterpreter, lambdaStillGoing)
    def self.Nx01(lambdaDisplay, lambdaHelpDisplay, lambdaPromptInterpreter, lambdaStillGoing)
        loop {
            return if !lambdaStillGoing.call()
            system("clear")
            lambdaDisplay.call()
            puts lambdaHelpDisplay.call().yellow
            userInput = LucilleCore::askQuestionAnswerAsString("-> ")
            break if userInput == ""
            lambdaPromptInterpreter.call(userInput)
        }
    end
end
