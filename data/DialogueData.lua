-- Dialogue data for all characters
local Dialogues = {
    tutorial = {
        { character = "duckie", text = "Use WASD or Arrow Keys to move around." },
        { character = "duckie", text = "Hold the key to walk around the room." },
        { character = "duckie", text = "Press E to talk to characters and interact." },
        { character = "duckie", text = "Press F to enter doors and portals." },
        { character = "duckie", text = "Explore the room and interact with objects." },
        { character = "duckie", text = "Start by checking the sink." },
    },

    scene1 = {
    { character = "duckie", text = "The glasses and plates are still here… unwashed." },
    { character = "duckie", text = "Mom used to clean these every morning." },
    { character = "duckie", text = "Ever since she got sick, the house has felt messier. Quieter too." },
    { character = "duckie", text = "I try to help, but it’s not the same." },
    },
    
    scene2 = {
    { character = "duckie", text = "This is my room." },
    { character = "duckie", text = "Father says I should rest more…" },
    { character = "duckie", text = "But resting won’t fix anything." },
    { character = "duckie", text = "I keep thinking…" },
    { character = "duckie", text = "There has to be a way to help Mom." },
    },
    
    scene3 = {
    { character = "duckie", text = "This was taken when Mom and Dad were still together." },
    { character = "duckie", text = "We used to laugh a lot back then." },
    { character = "duckie", text = "..." },
    { character = "duckie", text = "I miss those days." },
    },
    
    scene4 = {
    { character = "duckie", text = "Mom… I’m here." },
    { character = "duckie", text = "She’s been sick for a long time now." },
    { character = "duckie", text = "Father says it’s because of our family’s curse." },
    { character = "duckie", text = "A curse that weakens us…" },
    { character = "duckie", text = "Especially when we eat the wrong things." },
    { character = "duckie", text = "A curse that makes our bodies weak." },
    { character = "duckie", text = "He promised he would find a way to break it." },
    { character = "duckie", text = "I just wish he’d come home soon." },
    },
    
    scene5 = {
    { character = "duckie", text = "Here you go, Mom. You should eat." },
    { character = "duckie", text = "Dad said this will help slow the sickness." },
    { character = "duckie", text = "(mom eats)" },
    { character = "duckie", text = "Do you feel any better, Mom?" },
    { character = "duckie", text = "Dad said the curse gets worse over time." },
    { character = "duckie", text = "That’s why he left…" },
    { character = "duckie", text = "To find a way to break it." },
    },

    scene6 = {
    { character = "duckie", text = "This lake…" },
    { character = "duckie", text = "We used to play here all the time." },
    { character = "duckie", text = "Mother would laugh whenever I splashed too much." },
    { character = "duckie", text = "Father would sit by the shore and watch us." },
    { character = "duckie", text = "Everything felt so warm back then." },
    { character = "duckie", text = "..." },
    { character = "duckie", text = "But now… Mother is sick." },
    { character = "duckie", text = "Father is gone." },
    { character = "duckie", text = "When I look at the water, I remember those days." },
    { character = "duckie", text = "And it hurts too much." },
    { character = "duckie", text = "I don’t think I can touch the lake anymore." },
    },

    scene7 = {
    { character = "duckie", text = "Today feels different." },
    { character = "duckie", text = "I can’t just wait anymore." },
    { character = "duckie", text = "I think I remember Dad keeping a journal of some sort." },
    { character = "duckie", text = "It had notes about ingredients…Enough to make a stew." },
    },

    scene8 = {
    { character = "duckie", text = "This is Dad’s journal." },
    { character = "duckie", text = "(opens journal)" },
    { character = "duckie", text = "He wrote down all the ingredients needed to break the curse." },
    { character = "duckie", text = "They’re supposed to be cooked together into a stew." },
    { character = "duckie", text = "Dad said the stew would slowly weaken the curse…" },
    { character = "duckie", text = "One ingredient at a time." },
    { character = "duckie", text = "..." },
    { character = "Journal", text = "To my child…" },
    { character = "Journal", text = "The curse is not the end." },
    { character = "Journal", text = "Follow these steps to craft the Fish Stew." },
    { character = "Journal", text = "It is the only cure." },

    { character = "Journal", text = "Step 1: Whisper Weed." },
    { character = "Journal", text = "Found in the Whisper Willows." },
    { character = "Journal", text = "Do not be seen by the Sunken Owls." },
    { character = "Journal", text = "Do not be heard." },

    { character = "Journal", text = "Step 2: Ashroot Bulb." },
    { character = "Journal", text = "Scattered across the Ash Lands." },
    { character = "Journal", text = "Beware the Fiery Fox." },

    { character = "Journal", text = "Final Step: The Milkfish." },
    { character = "Journal", text = "Hidden deep beneath the hill lies the lake that contains it." },
    { character = "Journal", text = "The cure is almost complete." },
    { character = "duckie", text = "..." },

    { character = "duckie", text = "He left to gather them himself…" },
    { character = "duckie", text = "But he hasn’t come back for months." },
    { character = "duckie", text = "..." },
    { character = "duckie", text = "Mom’s condition keeps getting worse." },
    { character = "duckie", text = "If the stew is the only way…" },
    { character = "duckie", text = "Then I have to finish it." },
    { character = "duckie", text = "But before I go on my journey…" },
    { character = "duckie", text = "I should probably take a stroll in the town square." },
    { character = "duckie", text = "And meet some of my neighbors." },
    { character = "duckie", text = "It’s been a long time since I went outside." },
    },
    
    beakynpc = {
        { character = "beaky", text = "I could waddle on the porch... or pretend to be a statue... or maybe do a dramatic flop in the garden. Decisions, decisions... ah, the life of a sophisticated duck!" }
    },
    
    flappynpc = {
        { character = "flappy", text = "Waddlin' on your lawn, spittin' bars so fly, even your garden gnomes gotta sigh!" }
    },
    
    mrfeathernpc = {
        { character = "mrfeather", text = "Honestly, must one endure such... uncultured racket at all hours?" }
    },
    
    waddlenc = {
        { character = "waddle", text = "Just glidin' through life, one waddle at a time!" }
    },
    
    mrandynpc = {
        { character = "mrandy", text = "Ah, Ducky... it's good to see you walking around." },
        { character = "mrandy", text = "How is your mother doing these days?" },
        { character = "mrandy", text = "I've been meaning to visit, but my legs aren't what they used to be." },
        { character = "mrandy", text = "Your father was always devoted." },
        { character = "mrandy", text = "I pray he finds what he's looking for." },
        { character = "mrandy", text = "Be strong, child. Your mother needs you." }
    },
    
    shadyducknpc = {
        { character = "shadyduck", text = "Heh... you look tired, kid." },
        { character = "shadyduck", text = "Long days, heavy thoughts?" },
        { character = "shadyduck", text = "Maybe something warm would help." },
        { character = "shadyduck", text = "Fresh bread. Soft. Filling." },
        { character = "shadyduck", text = "People say it brings comfort." },
        { character = "shadyduck", text = "Care to buy some?" }
    },
    
    kurtnpc = {
        { character = "kurt", text = "Ducky... wait." },
        { character = "kurt", text = "I saw you talking to that duck." },
        { character = "kurt", text = "I don't think he's good company." },
        { character = "kurt", text = "Some things may look helpful, but aren't." },
        { character = "kurt", text = "Please... be careful with what you bring home." }
    },
    
    ritanpc = {
        { character = "rita", text = "You look like you haven't slept." },
        { character = "rita", text = "My mother was sick once too... just like yours." },
        { character = "rita", text = "I remember feeling so helpless." },
        { character = "rita", text = "We did something to help her..." },
        { character = "rita", text = "But I can't remember what it was." },
        { character = "rita", text = "I'm sorry." },
        { character = "rita", text = "If I remember, I'll come tell you. I promise." },
        { character = "duckie", text = "Alright! I think I met most of my neighbours already." },
        { character = "duckie", text = "I should probably go to my first destination." },
    }

    scene9 = {
    { character = "duckie", text = "This place feels… quiet." },
    { character = "duckie", text = "The air is thick, but calm." },
    { character = "duckie", text = "I don’t hear much." },
    { character = "duckie", text = "Just soft sounds…" },
    { character = "duckie", text = "Like the land is breathing." },
    { character = "duckie", text = "Father mentioned something like this in his notes…" },
    { character = "duckie", text = "It doesn’t feel safe, but…" },
    { character = "duckie", text = "I think I can manage." },
    { character = "duckie", text = "I’ll start here." },
    },

    scene10 = {
    { character = "duckie", text = "I finally got the first ingredient!" },
    { character = "duckie", text = "Two more to go!" },
    { character = "duckie", text = "According to the journal, the next item is located in the Ash Lands." },
    { character = "duckie", text = "I should get going…" },
    },

    scene11 = {
    { character = "duckie", text = "It’s hot…" },
    { character = "duckie", text = "The air feels heavy." },
    { character = "duckie", text = "Like it’s pressing down on me." },
    { character = "duckie", text = "Every step feels wrong…" },
    { character = "duckie", text = "Like the land itself is warning me." },
    { character = "duckie", text = "Nothing here looks alive for long." },
    { character = "duckie", text = "Father would never send me somewhere like this without reason." },
    { character = "duckie", text = "I don’t think this path was meant to be easy." },
    { character = "duckie", text = "Still…" },
    { character = "duckie", text = "If the cure is here, I have to keep going." },
    },

    scene12 = {
    { character = "duckie", text = "The second ingredient…" },
    { character = "duckie", text = "I really did it." },
    { character = "duckie", text = "I am halfway finished on this journey." },
    { character = "duckie", text = "I hope I could make them both proud." },
    { character = "duckie", text = "I hope I’m ready." },
},

    scene13 = {
    { character = "duckie", text = "This is it…" },
    { character = "duckie", text = "This is the final stretch to complete the cure." },
    { character = "duckie", text = "Time to move." },
    },

    condition1 = {
    { character = "duckie", text = "I shouldn’t rush." },
    { character = "duckie", text = "Father’s journal mentioned starting somewhere quiet…" },
    { character = "duckie", text = "If I skip steps, I might miss something important." },
    { character = "duckie", text = "I’ll go to Whisper first." },
    },

    condition2 = {
    { character = "duckie", text = "I don’t think I’m ready for this yet." },
    { character = "duckie", text = "Father’s journal mentioned another ingredient before this…" },
    { character = "duckie", text = "If I skip Ash, the cure won’t be complete." },
    { character = "duckie", text = "I should head there first." },
    },

    condition3 = {
    { character = "duckie", text = "I am quite suspicious of him…" },
    { character = "duckie", text = "Maybe I should try to not get involved with him…" },
    },

}

return Dialogues

