local DialogueManager = require('src.util.DialogueManager')
local ObjectiveData = require('data.ObjectiveData')

local StoryManager = {}

function StoryManager:new()
    local self = {
        -- Dialogue system
        dialogueManager = DialogueManager:new(),
        
        -- Pending dialogue after map transition
        pendingObjectiveDialogue = nil,
        
        -- Story progression tracking
        currentScene = "tutorial",  -- Current scene in the story
        completedScenes = {},       -- List of completed scene keys
        
        -- Objective tracking
        currentObjective = "obj1",  -- Current objective ID
        completedObjectives = {},   -- List of completed objectives
        
        -- Path tracking (3 possible endings)
        storyPath = "none",  -- Options: "none", "father", "cure_with_bread", "cure_without_bread"
        
        -- Decision tracking
        metShadyDuck = false,
        boughtBread = false,
        talkedToKurt = false,
        
        -- Ingredient collection
        hasWhisperWeed = false,
        hasAshrootBulb = false,
        hasMilkfish = false,
        
        -- NPC interactions
        npcDialoguesCompleted = {},
        
        -- State flags
        tutorialComplete = false,
        journalRead = false,
        readyForIngredients = false,
        curePrepared = false,
        
        -- Active state
        isShowingDialogue = false
    }
    
    return setmetatable(self, { __index = StoryManager })
end

function StoryManager:init()
    self.dialogueManager:enter()
end

function StoryManager:startTutorial()
    self:playScene("tutorial")
end

function StoryManager:playScene(sceneKey, onComplete)
    self.currentScene = sceneKey
    self.isShowingDialogue = true
    
    local callback = function()
        self.isShowingDialogue = false
        table.insert(self.completedScenes, sceneKey)
        
        -- Auto-advance objectives based on scene completion
        self:advanceObjective(sceneKey)
        
        if onComplete then
            onComplete()
        end
    end
    
    self.dialogueManager:startDialogue(sceneKey, callback)
end

function StoryManager:advanceObjective(sceneKey)
    -- Map scenes to their next objectives
    local progressionMap = {
        tutorial = "obj1",
        scene1 = "obj2",
        scene2 = "obj3",
        scene3 = "obj4",
        scene4 = "obj5",
        scene5 = "obj6",
        scene6 = "obj7",
        scene7 = "obj8",
        scene8 = "obj9",
        -- NPCs in town square
        mrandynpc = "obj11",
        shadyducknpc = "obj12",
        kurtnpc = "obj13",
        ritanpc = "obj14",
        -- Journey begins
        scene9 = "obj15",
        scene10 = "obj16",
        scene11 = "obj17",
        scene12 = "obj18",
    }
    
    local nextObj = progressionMap[sceneKey]
    if nextObj then
        if self.currentObjective then
            table.insert(self.completedObjectives, self.currentObjective)
        end
        self.currentObjective = nextObj
    end
end

function StoryManager:markObjectiveComplete(objectiveId)
    if self.currentObjective == objectiveId then
        table.insert(self.completedObjectives, objectiveId)
        -- Advance to next objective based on story logic
    end
end

function StoryManager:getCurrentObjectiveText()
    if not self.currentObjective then
        return "Explore"
    end
    
    local objective = ObjectiveData[self.currentObjective]
    if objective then
        return objective.text
    end
    
    return "Continue your journey"
end

function StoryManager:isSceneCompleted(sceneKey)
    for _, completed in ipairs(self.completedScenes) do
        if completed == sceneKey then
            return true
        end
    end
    return false
end

function StoryManager:playNPCDialogue(npcKey, onComplete)
    if self.npcDialoguesCompleted[npcKey] then
        return -- Already talked to this NPC
    end
    
    self.isShowingDialogue = true
    
    local callback = function()
        self.isShowingDialogue = false
        self.npcDialoguesCompleted[npcKey] = true
        
        -- Track special NPC interactions
        if npcKey == "shadyducknpc" then
            self.metShadyDuck = true
        elseif npcKey == "kurtnpc" then
            self.talkedToKurt = true
        end
        
        -- Advance objectives for NPC conversations
        self:advanceObjective(npcKey)
        
        if onComplete then
            onComplete()
        end
    end
    
    self.dialogueManager:startDialogue(npcKey, callback)
end

function StoryManager:collectIngredient(ingredientType)
    if ingredientType == "whisperWeed" then
        self.hasWhisperWeed = true
        self:playScene("scene10") -- Got first ingredient
    elseif ingredientType == "ashrootBulb" then
        self.hasAshrootBulb = true
        self:playScene("scene12") -- Got second ingredient
    elseif ingredientType == "milkfish" then
        self.hasMilkfish = true
        -- Check if ready to prepare cure
        if self.hasWhisperWeed and self.hasAshrootBulb then
            self:checkCurePathDecision()
        end
    end
end

function StoryManager:handleObjectiveItem(itemType, mapManager, hasTargetMap)
    -- Normalize itemType to lowercase for case-insensitive matching
    local normalizedItemType = itemType:lower()
    
    -- Map objective items to their scenes
    local itemSceneMap = {
        sink = "scene1",
        duckroom = "scene2",
        duckyroom = "scene2",
        pictureframe = "scene3",
        momroom = "scene4",
        parentroom = "scene4",
        mamaduck = "scene5",
        food = "scene5",
        lake = "scene6",
        inside = "scene7",
        journal = "scene8"
    }
    
    local sceneKey = itemSceneMap[normalizedItemType]
    
    if sceneKey then
        -- If this item has a targetMap, don't play dialogue now - set it as pending
        if hasTargetMap then
            self.pendingObjectiveDialogue = sceneKey
            return true
        end
        
        -- Special handling for journal - hide the Journal layer
        if normalizedItemType == "journal" then
            self.journalRead = true
            if mapManager then
                mapManager:hideLayer("Journal")
            end
        end
        
        -- Play the corresponding scene
        self:playScene(sceneKey)
        
        -- Mark item as collected in map manager
        if mapManager then
            mapManager:collectObjectiveItem(itemType)
        end
        
        return true
    end
    
    return false
end

function StoryManager:checkCurePathDecision()
    -- This should be called after getting all 3 ingredients
    -- The player should decide whether to add bread or not
    if self.boughtBread then
        self.storyPath = "cure_with_bread"
        -- Load Route 2 dialogues
    else
        self.storyPath = "cure_without_bread"
        -- Load Route 3 dialogues
    end
end

function StoryManager:checkPendingDialogue()
    if self.pendingObjectiveDialogue then
        local sceneToPlay = self.pendingObjectiveDialogue
        self.pendingObjectiveDialogue = nil
        self:playScene(sceneToPlay)
        return true
    end
    return false
end

function StoryManager:buyBread()
    self.boughtBread = true
    -- Trigger bread scene dialogue if needed
end

function StoryManager:chooseFatherPath()
    self.storyPath = "father"
    -- Ending 1: Join with father
end

function StoryManager:update(dt)
    if self.isShowingDialogue then
        self.dialogueManager:update(dt)
    end
end

function StoryManager:draw()
    if self.isShowingDialogue then
        self.dialogueManager:draw()
    end
end

function StoryManager:isActive()
    return self.isShowingDialogue
end

function StoryManager:nextDialogue()
    if not self.isShowingDialogue then
        return
    end
    
    -- Check if dialogue manager is actually active
    if not self.dialogueManager._isActive then
        -- Dialogue was closed but flag wasn't cleared
        self.isShowingDialogue = false
        return
    end
    
    -- If text is still animating, complete it instantly
    if not self.dialogueManager.isTextComplete then
        self.dialogueManager.displayedText = self.dialogueManager.fullText
        self.dialogueManager.isTextComplete = true
        return
    end
    
    -- Otherwise, advance to next dialogue
    self.dialogueManager.currentDialogueIndex = self.dialogueManager.currentDialogueIndex + 1
    
    if self.dialogueManager.currentDialogueIndex > #self.dialogueManager.dialogues then
        -- Dialogue complete - ensure cleanup
        self.dialogueManager._isActive = false
        self.isShowingDialogue = false
        
        -- Call completion callback
        if self.dialogueManager.onComplete then
            local callback = self.dialogueManager.onComplete
            self.dialogueManager.onComplete = nil  -- Clear callback to prevent double-call
            callback()
        end
    else
        -- Load next dialogue
        self.dialogueManager:loadDialogue(self.dialogueManager.currentDialogueIndex)
    end
end

-- Save/Load functionality for persistence
function StoryManager:getSaveData()
    return {
        currentScene = self.currentScene,
        completedScenes = self.completedScenes,
        currentObjective = self.currentObjective,
        completedObjectives = self.completedObjectives,
        storyPath = self.storyPath,
        metShadyDuck = self.metShadyDuck,
        boughtBread = self.boughtBread,
        talkedToKurt = self.talkedToKurt,
        hasWhisperWeed = self.hasWhisperWeed,
        hasAshrootBulb = self.hasAshrootBulb,
        hasMilkfish = self.hasMilkfish,
        npcDialoguesCompleted = self.npcDialoguesCompleted,
        tutorialComplete = self.tutorialComplete,
        journalRead = self.journalRead,
        readyForIngredients = self.readyForIngredients,
        curePrepared = self.curePrepared
    }
end

function StoryManager:loadSaveData(data)
    if not data then return end
    
    self.currentScene = data.currentScene or "tutorial"
    self.completedScenes = data.completedScenes or {}
    self.currentObjective = data.currentObjective or "obj1"
    self.completedObjectives = data.completedObjectives or {}
    self.storyPath = data.storyPath or "none"
    self.metShadyDuck = data.metShadyDuck or false
    self.boughtBread = data.boughtBread or false
    self.talkedToKurt = data.talkedToKurt or false
    self.hasWhisperWeed = data.hasWhisperWeed or false
    self.hasAshrootBulb = data.hasAshrootBulb or false
    self.hasMilkfish = data.hasMilkfish or false
    self.npcDialoguesCompleted = data.npcDialoguesCompleted or {}
    self.tutorialComplete = data.tutorialComplete or false
    self.journalRead = data.journalRead or false
    self.readyForIngredients = data.readyForIngredients or false
    self.curePrepared = data.curePrepared or false
end

return StoryManager
