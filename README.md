Heyo, this is a prototypeRPG I'm making to learn Godot

Here's how things are supposed to functions
I'm going to keep updating this until the GameJam starts so maybe it'll look better tommorow

______
CREDITS - THINGS I DON'T OWN
______
ART)
Ailment Icons, Element Icons, Crush Icon and Stat Icons - [SunGraphica] 450 clean and minimal game Icon ultimate pack

Music)
Blair Dame's Theme - [Takayuki Aihara] Fighting Layer
...Delve!! - [John "Joy" Tay] https://youtu.be/d7ZqYAlUlAU
Event Battle - [Toshiyuki Sudo, Shinji Ushiroda, Yumi Takahashi, Megumi Inoue] Miitopia

SFX)
beam.ogg used with Neutral Ballistic attacks- took from Power Bomberman
clear_02_ab2Db_low.ogg used with Healing - took from Mixolumia
fssmash_1.ogg used with slash attacks - stock sword sfx
fspecial.ogg used with Condition Buffs - unsure
heavy1.ogg used with NeutralPhysical attacks - unsure

______
ISSUES
______
*In general STABILITY

______
TODO
______
*Make functioning menu for gear and items
*Implement gear and item selection
*Save system
*Implement other EnemyAI types(So far only random)

______
LOFTY TODOS
______
*Implement Summon moves for players and enemies (Players: Swap, Enemies actually add in new entities) ||
*Better Damage displays
*Visuals of any kind
*Fix/Balance other enemies

______
STATS
_____
*HP:    Health Points, when 0 you die
*LP:    Mana, they're only called LP because I played Okage: Shadow King lol
*TP:    Added up with the rest of the team's TP to form a total TP Pool
*CPU:   Determines how many Chips you can equip

*strength:  Physical Attack
*toughness:  Physical Defense
*ballistics:  Ballistic Attack (aka magic)
*resistance:  Ballistic Defense
*speed:  Lowers TP cost of moves
*luck:  Raises chance of getting crit/ailment hits and lowers opponents chances of doing the same to you

_______
PROPERTIES
_______
Elements: There are four regular elements: Fire, Water, Elec and Neutral. 
Fire, Water and Elec have a RPS system against eachother  Fire beats Elec,  Elec beats Water, Water beats Fire
the winning element takes less damage, deals more damage and has a higher chance to inflict Ailments.
If a move has a non-Neutral element tied to it, the defender will have to take that element's damage
Otherwise offensive element depends on user's element (Neutral using neutral will be just neutral)

PhyElements: Some moves have PhyElements Alash/Crush/Pierce. If an entity has a Weakness, it'll deal more damage,
and Resistance will deal less damage. However Weaknesses take priority even if they have a Resistance at the same time

There are several other offensive elements but they likely won't be used

Weakness/Resist: Entities can also have Elemental Weak/Resists on top of their normal element

_______
BUFFS
_______
Four stats can be buffed twice, each stack gives a 30% boost to:
Attack, Defense, Speed or Luck
They don't directly buff stats but they will be there to help any calc with those stats

______
AILMENTS
______
Ailments, aka Status Consitions
Most can be stacked 3 times for worsening effects with the only exception being Overdrive
You can only have one Ailment stacked
They probably won't be implemented by the time the GameJam starts but if they are I will list their functions

XSofts are a seperate kind of Status Effect
The first Soft of a certain element will make the entity take 15% more damage to that element
proceeeding Softs of the same element will add 10%
The six softs are Fire,Water,Elec,Slash,Crush & Pierce 
They will be applied whener you crit, with PhyElements taking priority
You can only have a total of 3 softs of any type

______
CONDITIONS
______
*Status Ailments that can't be stacked on their own
*charge - x2.5 damage for a physical attack
*targetted - Entity on said side is the only one that can be attacked, random target will also exclusively target them
*lucky - Autowin chances

*ex. You can only charge once but you can have charge with lucky and/or targetted

_______
MOVES
_______

Move Properties)
*Physical: Deal Physical Damage tend to cost HP for players
*Ballistic: Deal Ballistic Damage tend to cost LP for players
*Bomb: Deal Damage without the user's attack or enemy's defense stat tend to be items
*Buff: Chance a property of the target[Stat Buff, Condition or Element] tend to cost LP for players
*Heal: Heal HP and/or remove Ailments tend to cost LP for players
*Aura: Add a feild condition tend to be items
*Summon: Add an entity to the field (likely won't be implemented) Enemy Exclusive
*Ailment: Inflict a certain Ailment/XSoft, if chance is 200% it's guaranteed tends to be paired with another property
*Misc: If needed use a custom function

Move Targets)
*Single: Attack a single entity X times
*Group: Attack a group of entities of the same element X times. If there is only one entity, attack them 2X times
*Random: For X times, attack a random enemy
*Self: You
*All: Attack every entity X times

______
TP MANAGEMENT
______
It determines what moves you can use in a turn to turn basis, think of it like mana in a card game
Every character's TP is collected into one per team
Both sides start with full TP and every proceeding turn they gain half of their max back
For now you can't use a move if it goes over the team's currentTP

______
OVERDRIVE
______
It's a strange move I tried to implement in my prototype
It comes from Okage: Shadow King
It gives an all three things:
1: A damage boost while the condition is up
2: Access to Burst, a high damage all targetting move that consumes Overdrive upon use
3: Immediete access to another turn

Differences:
Since this isn't ATB it instead gives the target a free turn
They still have to pay TP costs so it's effectively very pricey

Despite the decently high HP Cost it's a super strong move 
but being on the main character who not only game overs upon death but is the only healer for half the game
it's super fun and risky to use and I love it
So here it is in the prototype

______
CHIPS
______
Chips are equipabbles that will give the user different effects
You can only equip as many as your CPU count can hold



*Red: Affects aspects like moveset, move costs, and move properties
*Blue: Affects a character's properties from element, immunities, resistances, and conditions
*Yellow: Affects base stats

______
ITEMS
______


______
GEAR
______
Character Exlusive Equipabbles

Generally characters will have two types of gear that have different types of buffs
There will be stronger versions of those two types

The exception is with the DREAMER whose gear varies wildly
