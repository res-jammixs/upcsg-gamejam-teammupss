local ObjectiveData = {
    -- Tutorial and Early Game
    obj1  = { prereq = "tutorial", text = "Go to the Sink" },
    obj2  = { prereq = "scene1", text = "Go to Ducky's Room" },
    obj3  = { prereq = "scene2", text = "Pick up the Picture Frame" },
    obj4  = { prereq = "scene3", text = "Go find Mom" },
    obj5  = { prereq = "scene4", text = "Talk to Mom" },
    obj6  = { prereq = "scene5", text = "Go to the Lake outside" },
    obj7  = { prereq = "scene6", text = "Go back inside" },
    obj8  = { prereq = "scene7", text = "Locate the Journal" },
    obj9  = { prereq = "scene8", text = "Go to the Town Square" },
    
    -- Town Square NPCs
    obj10 = { prereq = "none", text = "Talk to Mr. Andy" },
    obj11 = { prereq = "mrandynpc", text = "Talk to the Shady Duck" },
    obj12 = { prereq = "shadyducknpc", text = "Talk to Kurt" },
    obj13 = { prereq = "kurtnpc", text = "Talk to Rita" },
    
    -- Journey for Ingredients
    obj14 = { prereq = "ritanpc", text = "Go to the Whisper Willows" },
    obj15 = { prereq = "scene9", text = "Find the Whisper Weed" },
    obj16 = { prereq = "scene10", text = "Go to the Ash Lands" },
    obj17 = { prereq = "scene11", text = "Find 10 Ashroot Bulb" },
    obj18 = { prereq = "scene12", text = "Go to the Hill with the Thousand Turns" },
    obj19 = { prereq = "scene13", text = "Find the Milkfish" },
    
    -- Ending Paths
    -- Route 1: with bread
    obj20 = { prereq = "milkfish_collected", text = "Buy Bread from the Shady Duck (Optional)" },
    obj21 = { prereq = "bread_bought", text = "Prepare the Cure with Bread" },
    obj22 = { prereq = "cure_prepared_bread", text = "Feed Mom the Cure" },
    obj23 = { prereq = "mom_fed_bread", text = "Check on Mom" },

    -- Route 2: pure cure
    obj24 = { prereq = "milkfish_collected", text = "Prepare the Pure Cure" },
    obj25 = { prereq = "cure_prepared_pure", text = "Feed Mom the Pure Cure" },
    obj26 = { prereq = "mom_fed_pure", text = "Check on Mom" },
    
    -- Route 3: Father's Path
    obj27 = { prereq = "father_appears", text = "Talk to Father" },
    obj28 = { prereq = "father_dialogue", text = "Make Your Choice" },
}

return ObjectiveData
