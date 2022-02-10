# encoding: UTF-8

class Topping

    # Topping::getText()
    def self.getText()
        KeyValueStore::getOrNull(nil, "316B44F4-61DF-4549-81C9-54673FF950EB") || "" 
    end

    # Topping::setText(text)
    def self.setText(text)
        KeyValueStore::set(nil, "316B44F4-61DF-4549-81C9-54673FF950EB", text.strip)
    end

    # Topping::applyTransformation()
    def self.applyTransformation()
        text = Topping::getText()
        Utils::dropTextAtBinTimeline("Catalyst-Top.txt", text)
        text = SectionsType0141::applyNextTransformationToText(text)
        Topping::setText(text)
    end

    # Topping::top()
    def self.top()
        text = Topping::getText()
        Utils::dropTextAtBinTimeline("Catalyst-Top.txt", text)
        text = Utils::editTextSynchronously(text)
        Topping::setText(text)
    end
end


