# encoding: UTF-8

class Topping

    # Topping::getText(focus)
    def self.getText(focus)
        KeyValueStore::getOrNull(nil, "316B44F4-61DF-4549-81C9-54673FF950EB:#{focus}") || "" 
    end

    # Topping::setText(focus, text)
    def self.setText(focus, text)
        KeyValueStore::set(nil, "316B44F4-61DF-4549-81C9-54673FF950EB:#{focus}", text.strip)
    end

    # Topping::applyTransformation(focus)
    def self.applyTransformation(focus)
        text = Topping::getText(focus)
        Utils::dropTextAtBinTimeline("Catalyst-Top-#{focus}.txt", text)
        text = SectionsType0141::applyNextTransformationToText(text)
        Topping::setText(focus, text)
    end

    # Topping::top(focus)
    def self.top(focus)
        text = Topping::getText(focus)
        Utils::dropTextAtBinTimeline("Catalyst-Top-#{focus}.txt", text)
        text = Utils::editTextSynchronously(text)
        Topping::setText(focus, text)
    end
end


