. "$PSScriptRoot\Functions.ps1"
#######################################################################################################################################################################################

$Class = "SK"
$Level = 50
$OffenseSkill = 200
$DuelWieldSkill = 0
$Strength = 150


#Tab or comma Separated list of weapons data
# Name,Type,Damage,Delay,Str Bonus

$Weapons = @"
Wurmslayer	1hs	25	40	5
Sword of Skyfire	1hs	10	22	0
Tentacle Whip	1hs	4	25

Combine Two Handed Sword	2hs	12	43
Executioner's Axe	2hs	25	50
Deepwater Harpoon	2hs	18	40

Woe	1hp	5	29
Sionachie's Partisan	1hp	9	19
Jarsath Trident	1hp	11	22	5

Rod of Annihilation	1hb	60	40
Wraith Bone Hammer	1hb	8	26	5
Jade Mace	1hb	9	18

Glowing Wooden Crook	2hb	11	35
Tranquil Staff	2hb	29	30
Springwood Stave	2hb	31	42

Narandi's Lance	2hp	44	45	8
Messenger of the Queen	2hp	20	40	5
Runed Othmir Spear	2hp	16	46	0
"@



$results = Get-WeaponsDPSFromString -Weapons $weapons -Class $Class -Level $Level -OffenseSkill $OffenseSkill -Strength $Strength -DuelWieldSkill $DuelWieldSkill
Out-WeaponDPSResults $results -debug