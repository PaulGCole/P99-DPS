class WeaponData {
    [string]$Name
    [WeaponType]$Type
    [string]$Dmg
    [string]$Delay
    [int]$StrengthBonus # Added to the players existing str
}

enum WeaponType {
    Onehb
    Onehs
    Onehp
    Twohs
    Twohb
    Twohp
}

$Script:Class =""
$Script:Level =0
$Script:OffenseSkill=0
$Script:DuelWieldSkill=0
$Script:Strength=0
$Script:DamageCap=0

#######################################################################################################################################################################################
# Converting a block of weapon data in a string to an array of weapon data

# Global constant for splitting characters
$splitChars = '[\t;,|]+'



# Function to automatically map string to WeaponType enum by converting the number and matching the type
function ConvertTo-WeaponType ([string]$typeString) {
    # Extract the number prefix (e.g., 1 or 2) and the rest of the type (e.g., "hb")
    if ($typeString -match '^(\d+)([a-z]+)$') {
        $number = [int]$matches[1]
        $suffix = $matches[2]

        # Convert the number to a word
        $word = ($number -eq 1) ? "One" : ($number -eq 2) ? "Two" : ""
        $enumString = "$word$suffix"

        # Check if the generated string exists in the WeaponType enum
        if ([enum]::IsDefined([WeaponType], $enumString)) {
            return [WeaponType]::Parse([WeaponType], $enumString)
        }
    }
        
    Throw "WeaponType not found for: $enumString"
}



# Function to parse a single line of weapon data
function ConvertTo-WeaponData ([string]$line) {
    # Split the line by any of the specified separators
    $parts = $line -split $splitChars

    # Populate the object
    $weapon = [WeaponData]::new()
    $weapon.Name = $parts[0].Trim()
 
    # Automatically map the weapon type
    $weapon.Type = ConvertTo-WeaponType $parts[1].Trim()

    $weapon.Dmg = $parts[2].Trim()
    $weapon.Delay = $parts[3].Trim()

    # Handle optional StrengthBonus (may be +, -, or non-existent)
    if ($parts.Count -ge 5 -and $parts[4] -match '([+-]?\d+)') {
        $weapon.StrengthBonus = [int]$matches[1]
    }
    else {
        $weapon.StrengthBonus = 0 # Default to 0 if no bonus is present
    }

    return $weapon
}



# Function to create the array of WeaponData objects from a text block
function New-WeaponArray ([string]$textBlock) {
    $lines = $textBlock -split "`n"

    # Parse each line and create WeaponData objects
    $weapons = foreach ($line in $lines) {
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            ConvertTo-WeaponData $line
        }
    }

    return $weapons
}



#######################################################################################################################################################################################
# Calculating Weapon Damage Bonus

$OneHanded = @(1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10, 10, 11, 11, 11, 12, 12, 12, 13, 13)

$TwoHanded = @(
    @(15, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10, 10, 11, 11, 11, 12, 12, 12, 13, 13, 13, 14, 14),
    @(20, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10, 10, 11, 11, 11, 12, 12, 12, 13, 13, 13, 14, 14),
    @(21, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10, 10, 11, 11, 11, 12, 12, 12, 13, 13, 13, 14, 14),
    @(22, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10, 10, 11, 11, 11, 12, 12, 12, 13, 13, 13, 14, 14),
    @(23, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10, 10, 11, 11, 11, 12, 12, 12, 13, 13, 13, 14, 14),
    @(24, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10, 10, 11, 11, 11, 12, 12, 12, 13, 13, 13, 14, 14),
    @(25, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10, 10, 11, 11, 11, 12, 12, 12, 13, 13, 13, 14, 14),
    @(26, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10, 10, 11, 11, 11, 12, 12, 12, 13, 13, 13, 14, 14),
    @(27, 2, 2, 2, 3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10, 10, 11, 11, 11, 12, 12, 12, 13, 13, 13, 14, 14),
    @(28, 1, 1, 2, 3, 3, 3, 4, 5, 5, 6, 6, 6, 8, 8, 8, 9, 9, 10, 11, 11, 11, 12, 13, 14, 16, 17, 17, 21, 21, 23, 25, 26, 28, 30, 31, 31, 33, 35),
    @(29, 1, 1, 2, 3, 3, 3, 4, 5, 5, 6, 6, 6, 8, 8, 8, 9, 9, 10, 11, 11, 11, 12, 13, 14, 16, 17, 17, 21, 22, 23, 25, 26, 29, 30, 31, 32, 34, 35),
    @(30, 1, 1, 2, 3, 3, 3, 4, 5, 5, 6, 6, 6, 8, 8, 8, 9, 9, 10, 11, 11, 11, 12, 13, 14, 16, 17, 18, 21, 22, 23, 25, 27, 29, 31, 32, 32, 34, 36),
    @(31, 1, 1, 2, 3, 3, 3, 4, 5, 5, 6, 6, 6, 8, 8, 8, 9, 9, 10, 11, 11, 11, 12, 13, 14, 16, 17, 18, 21, 22, 23, 25, 27, 29, 31, 32, 33, 34, 36),
    @(32, 1, 1, 2, 3, 3, 3, 4, 5, 5, 6, 6, 6, 8, 8, 8, 9, 9, 10, 11, 11, 11, 12, 13, 14, 16, 17, 18, 21, 22, 24, 26, 27, 30, 32, 32, 33, 35, 37),
    @(33, 1, 1, 2, 3, 3, 3, 4, 5, 5, 6, 6, 6, 8, 8, 8, 9, 9, 10, 11, 11, 11, 12, 13, 14, 16, 17, 18, 21, 22, 24, 26, 27, 30, 32, 33, 34, 35, 37),
    @(34, 1, 1, 2, 3, 3, 3, 4, 5, 5, 6, 6, 6, 8, 8, 8, 9, 9, 10, 11, 11, 11, 12, 13, 14, 16, 17, 18, 22, 22, 24, 26, 28, 30, 32, 33, 34, 36, 38),
    @(35, 1, 1, 2, 3, 3, 3, 4, 5, 5, 6, 6, 6, 8, 8, 8, 9, 9, 10, 11, 11, 11, 12, 13, 14, 16, 17, 18, 22, 23, 24, 26, 28, 31, 33, 34, 34, 36, 38),
    @(36, 1, 1, 2, 3, 3, 3, 4, 5, 5, 6, 6, 6, 8, 8, 8, 9, 9, 10, 11, 11, 11, 12, 13, 14, 16, 17, 18, 22, 23, 25, 27, 28, 31, 33, 34, 35, 37, 39),
    @(37, 1, 1, 2, 3, 3, 3, 4, 5, 5, 6, 6, 6, 8, 8, 8, 9, 9, 10, 11, 11, 11, 12, 13, 14, 16, 17, 18, 22, 23, 25, 27, 29, 31, 33, 34, 35, 37, 39),
    @(38, 1, 1, 2, 3, 3, 3, 4, 5, 5, 6, 6, 6, 8, 8, 8, 9, 9, 10, 11, 11, 11, 12, 13, 14, 16, 17, 18, 22, 23, 25, 27, 29, 32, 34, 35, 36, 38, 40),
    @(39, 1, 1, 2, 3, 3, 3, 4, 5, 5, 6, 6, 6, 8, 8, 8, 9, 9, 10, 11, 11, 11, 12, 13, 14, 16, 17, 18, 22, 23, 25, 27, 29, 32, 34, 35, 36, 38, 40),
    @(40, 2, 2, 3, 4, 4, 4, 5, 6, 6, 7, 7, 7, 9, 9, 9, 10, 10, 11, 12, 12, 12, 13, 14, 16, 18, 19, 20, 24, 25, 27, 29, 31, 34, 36, 37, 38, 40, 42),
    @(41, 2, 2, 3, 4, 4, 4, 5, 6, 6, 7, 7, 7, 9, 9, 9, 10, 10, 11, 12, 12, 12, 13, 14, 16, 18, 19, 20, 24, 25, 27, 29, 31, 34, 36, 37, 38, 40, 42),
    @(42, 2, 2, 3, 4, 4, 4, 5, 6, 6, 7, 7, 7, 9, 9, 9, 10, 10, 11, 12, 12, 12, 13, 14, 16, 18, 19, 20, 24, 25, 27, 29, 31, 34, 36, 37, 38, 40, 42),
    @(43, 4, 4, 5, 6, 6, 6, 7, 8, 8, 9, 9, 9, 11, 11, 11, 12, 12, 13, 14, 14, 14, 15, 16, 18, 20, 21, 22, 26, 27, 29, 31, 33, 37, 39, 40, 41, 43, 45),
    @(44, 4, 4, 5, 6, 6, 6, 7, 8, 8, 9, 9, 9, 11, 11, 11, 12, 12, 13, 14, 14, 14, 15, 16, 18, 20, 21, 22, 26, 27, 29, 32, 34, 37, 39, 40, 41, 43, 45),
    @(45, 5, 5, 6, 7, 7, 7, 8, 9, 9, 10, 10, 10, 12, 12, 12, 13, 13, 14, 15, 15, 15, 16, 17, 19, 21, 22, 23, 27, 28, 31, 33, 35, 38, 40, 42, 43, 45, 47),
    @(46, 6, 6, 7, 8, 8, 8, 9, 10, 10, 11, 11, 11, 13, 13, 13, 14, 14, 15, 16, 16, 16, 17, 18, 20, 22, 23, 24, 28, 30, 32, 34, 36, 40, 42, 43, 44, 46, 48),
    @(47, 6, 6, 7, 8, 8, 8, 9, 10, 10, 11, 11, 11, 13, 13, 13, 14, 14, 15, 16, 16, 16, 17, 18, 20, 22, 23, 24, 29, 30, 32, 34, 37, 40, 42, 43, 44, 47, 49),
    @(48, 6, 6, 7, 8, 8, 8, 9, 10, 10, 11, 11, 11, 13, 13, 13, 14, 14, 15, 16, 16, 16, 17, 18, 20, 22, 23, 24, 29, 30, 32, 35, 37, 40, 43, 44, 45, 47, 49),
    @(49, 7, 7, 8, 9, 9, 9, 10, 11, 11, 12, 12, 12, 14, 14, 14, 15, 15, 16, 17, 17, 17, 18, 19, 21, 23, 24, 25, 30, 31, 34, 36, 38, 42, 44, 45, 46, 49, 51),
    @(50, 7, 7, 8, 9, 9, 9, 10, 11, 11, 12, 12, 12, 14, 14, 14, 15, 15, 16, 17, 17, 17, 18, 19, 21, 23, 24, 26, 30, 31, 34, 36, 39, 42, 44, 46, 47, 49, 51),
    @(51, 7, 7, 8, 9, 9, 9, 10, 11, 11, 12, 12, 12, 14, 14, 14, 15, 15, 16, 17, 17, 17, 18, 19, 21, 23, 24, 26, 30, 31, 34, 36, 39, 42, 45, 46, 47, 49, 52),
    @(52, 8, 8, 9, 10, 10, 10, 11, 12, 12, 13, 13, 13, 15, 15, 15, 16, 16, 17, 18, 18, 18, 19, 20, 22, 24, 25, 27, 31, 33, 35, 38, 40, 44, 46, 47, 49, 51, 53),
    @(53, 8, 8, 9, 10, 10, 10, 11, 12, 12, 13, 13, 13, 15, 15, 15, 16, 16, 17, 18, 18, 18, 19, 20, 22, 24, 25, 27, 31, 33, 35, 38, 40, 44, 46, 48, 49, 51, 54),
    @(54, 8, 8, 9, 10, 10, 10, 11, 12, 12, 13, 13, 13, 15, 15, 15, 16, 16, 17, 18, 18, 18, 19, 20, 22, 24, 26, 27, 32, 33, 36, 38, 41, 44, 47, 48, 49, 52, 54),
    @(55, 9, 9, 10, 11, 11, 11, 12, 13, 13, 14, 14, 14, 16, 16, 16, 17, 17, 18, 19, 19, 19, 20, 21, 23, 25, 27, 28, 33, 34, 37, 39, 42, 46, 48, 50, 51, 53, 56),
    @(56, 9, 9, 10, 11, 11, 11, 12, 13, 13, 14, 14, 14, 16, 16, 16, 17, 17, 18, 19, 19, 19, 20, 21, 23, 25, 27, 28, 33, 34, 37, 40, 42, 46, 49, 50, 51, 54, 56),
    @(57, 9, 9, 10, 11, 11, 11, 12, 13, 13, 14, 14, 14, 16, 16, 16, 17, 17, 18, 19, 19, 19, 20, 21, 23, 25, 27, 28, 33, 34, 37, 40, 43, 46, 49, 50, 52, 54, 57),
    @(58, 10, 10, 11, 12, 12, 12, 13, 14, 14, 15, 15, 15, 17, 17, 17, 18, 18, 19, 20, 20, 20, 21, 22, 24, 26, 28, 29, 34, 36, 39, 41, 44, 48, 50, 52, 53, 56, 58),
    @(59, 10, 10, 11, 12, 12, 12, 13, 14, 14, 15, 15, 15, 17, 17, 17, 18, 18, 19, 20, 20, 20, 21, 22, 24, 26, 28, 29, 34, 36, 39, 41, 44, 48, 51, 52, 54, 56, 59),
    @(60, 10, 10, 11, 12, 12, 12, 13, 14, 14, 15, 15, 15, 17, 17, 17, 18, 18, 19, 20, 20, 20, 21, 22, 24, 27, 28, 30, 35, 36, 39, 42, 45, 49, 51, 53, 54, 57, 59),
    @(70, 14, 14, 15, 16, 16, 16, 17, 18, 18, 19, 19, 19, 21, 21, 21, 22, 22, 23, 24, 24, 24, 25, 26, 28, 31, 33, 35, 40, 42, 45, 48, 52, 56, 59, 61, 62, 65, 68),
    @(85, 19, 19, 20, 21, 21, 21, 22, 23, 23, 24, 24, 24, 26, 26, 26, 27, 27, 28, 29, 29, 29, 30, 31, 34, 37, 39, 41, 47, 49, 54, 57, 61, 66, 69, 72, 74, 77, 80),
    @(95, 22, 22, 23, 24, 24, 24, 25, 26, 26, 27, 27, 27, 29, 29, 29, 30, 30, 31, 32, 32, 32, 33, 34, 37, 40, 43, 45, 52, 54, 59, 62, 67, 73, 76, 79, 81, 84, 88),
    @(150, 40, 40, 41, 42, 42, 42, 43, 44, 44, 45, 45, 45, 47, 47, 47, 48, 48, 49, 50, 50, 50, 51, 52, 56, 61, 65, 69, 78, 82, 89, 94, 102, 110, 115, 119, 122, 127, 132)
)


function Get-DamageBonus {
    param (
        [int]$PlayerLevel, # Player level (integer between 28-65)
        [WeaponType]$Type, # Parameter for weapon type (enum)
        [int]$Delay # Delay (integer)
    )

    # Validate PlayerLevel
    if ($PlayerLevel -lt 28) { $PlayerLevel = 28 }
    if ( $PlayerLevel -gt 60) { $PlayerLevel = 60 }

    # Look up damage bonus based on weapon type
    switch ($Type) {
        { $_ -eq [WeaponType]::Onehb -or $_ -eq [WeaponType]::Onehs -or $_ -eq [WeaponType]::Onehp } {
            # Calculate index for lookup (PlayerLevel - 28)
            $index = $PlayerLevel - 28
            return $OneHanded[$index] # Return the bonus from the OneHanded array
        }

        { $_ -eq [WeaponType]::Twohs -or $_ -eq [WeaponType]::Twohb -or $_ -eq [WeaponType]::Twohp } {
            # Find the appropriate inner array based on the delay
            $innerArray = $TwoHanded | Where-Object { $_[0] -le $Delay } | Select-Object -Last 1
            if ($null -eq $innerArray) {
                throw "No inner array found for the specified delay."
            }
            # Calculate index for lookup (PlayerLevel - 28) (+1 for first element being the delay)
            $index = $PlayerLevel - 28 + 1
            return $innerArray[$index] # Return the bonus from the selected inner array
        }

        default {
            throw "Invalid WeaponType."
        }
    }
}

#######################################################################################################################################################################################
#Calculating Damage Cap

$DamageCap = 0


# Define the CharacterType enum
enum CharacterType {
    Caster
    Priest
    Melee
}
function Get-CharacterType([string]$className) {
    # Normalize the input to upper case for case-insensitive comparison
    $normalizedClassName = $className.ToUpper()

    # Define mappings for character types and their associated classes
    $classMappings = @{
        Caster = @("ENCHANTER", "ENC", "MAGICIAN", "MAG", "NECROMANCER", "NEC", "WIZARD", "WIZ")
        Priest = @("CLERIC", "CLR", "DRUID", "DRU", "SHAMAN", "SHM")
        Melee  = @("BARD", "BRD", "MONK", "MNK", "RANGER", "RNG", "ROGUE", "ROG", "PALADIN", "PAL", "SHADOWKNIGHT", "SHD", "SK", "WARRIOR", "WAR")
    }

    # Check each character type for a match
    foreach ($type in $classMappings.Keys) {
        if ($classMappings[$type] -contains $normalizedClassName) {
            return [CharacterType]::$type
        }
    }

    throw "Invalid class name: $className"
}





function Get-DamageCapForLevelAndType ([int]$level, [CharacterType]$characterType) {
    # Validate the level is between 1 and 60
    if ($level -lt 1 -or $level -gt 60) {
        throw "Level must be between 1 and 60."
    }

    # Define damage caps for each character type
    $damageCaps = @{
        [CharacterType]::Caster = @(
            @{ Range = 1..9; Cap = 6 }
            @{ Range = 10..19; Cap = 10 }
            @{ Range = 20..29; Cap = 12 }
            @{ Range = 30..39; Cap = 18 }
            @{ Range = 40..60; Cap = 20 }
        )
        [CharacterType]::Priest = @(
            @{ Range = 1..9; Cap = 9 }
            @{ Range = 10..19; Cap = 12 }
            @{ Range = 20..29; Cap = 20 }
            @{ Range = 30..39; Cap = 26 }
            @{ Range = 40..60; Cap = 40 }
        )
        [CharacterType]::Melee  = @(
            @{ Range = 1..9; Cap = 10 }
            @{ Range = 10..19; Cap = 14 }
            @{ Range = 20..29; Cap = 30 }
            @{ Range = 30..39; Cap = 60 }
            @{ Range = 40..60; Cap = 100 }
        )
    }

    # Get the damage cap table for the given character type directly using the enum
    $capsForType = $damageCaps[$characterType]

    # Determine the damage cap based on the level
    foreach ($entry in $capsForType) {
        if ($entry.Range -contains $level) {
            return $entry.Cap
        }
    }

    throw "Damage cap could not be determined."
}

#######################################################################################################################################################################################
# Put it all together

# Define the result class for DPS
class MaxDPSResult {
    [float]$MainHandDPS
    [float]$OffHandDPS
    [int]$MainHandDamage
    [int]$OffHandDamage
    [float]$Mod
    [int]$MainHandBonus
    [int]$MainHandDmgUncapped
}


function Get-DPSData {
    param (
        [int]$Level,
        [int]$OffenseSkill,
        [int]$Strength, 
        [WeaponType]$WeaponType,
        [int]$Damage,
        [int]$Delay,
        [int]$DamageCap,
        [int]$DuelWieldSkill
    )

      
    # Calculate Mod based on OffenseSkill and Strength
    $Mod = ($OffenseSkill + $Strength) / 100
    if ($Mod -lt 2) { $Mod = 2 }

    $BaseDamage = $Mod * $Damage
    $DuelWieldMod = if ($DuelWieldSkill -gt 0) { ($Level + $DuelWieldSkill) / 400 } else { 0 }

    # Calculate Main Hand Bonus
    $MainHandBonus = Get-DamageBonus -PlayerLevel $Level -Type $WeaponType -Delay $Delay 

    #For display purposes, what would the damage be if uncapped.
    $MainHandMaxDamageUncapped = $BaseDamage + $MainHandBonus

    # Calculate Max Main Hand Damage
    #Not sure which of these formulas is correct.....
    # $MainHandMaxDamage =  [math]::Min($$BaseDamage + $MainHandBonus, $DamageCap)
    $MainHandMaxDamage = [math]::Min($BaseDamage, $DamageCap) + $MainHandBonus

    # Calculate Offhand Damage using Dual Wield (if applicable)
    $OffHandMaxDamage = 0
    if ($WeaponType -eq [WeaponType]::Onehs -or $WeaponType -eq [WeaponType]::Onehb -or $WeaponType -eq [WeaponType]::Onehp ) {
        $OffHandMaxDamage = [math]::Min($BaseDamage * $DuelWieldMod, $DamageCap)
    }

    # Calculate DPS (Damage per second) for Main Hand and Off Hand
    $MainHandDPS = $MainHandMaxDamage / ($Delay / 10)
    $OffHandDPS = $OffHandMaxDamage / ($Delay / 10)
    
    # Return results as a class instance
    return [MaxDPSResult]@{
        MainHandDPS         = $MainHandDPS
        OffHandDPS          = $OffHandDPS
        MainHandDamage      = $MainHandMaxDamage
        OffHandDamage       = $OffHandMaxDamage
        Mod                 = $Mod
        MainHandBonus       = $MainHandBonus
        MainHandDmgUncapped = $MainHandMaxDamageUncapped
    }
}






# Define the class to hold result data
class WeaponDPSResult {
    [string]$WeaponName
    [WeaponType]$Type
    [float]$MainHandDPS
    [float]$OffHandDPS
    [int]$Damage
    [int]$Delay
    [int]$MainHandDamage
    [int]$OffHandDamage
    [int]$MainHandBonus
    [float]$Mod
    [int]$MainHandDmgUncapped
}

function Get-WeaponsDPS {
    param (
        [WeaponData[]]$Weapons, # Array of WeaponData
        [string]$Class, # Character class
        [int]$Level, # Player level
        [int]$OffenseSkill, # Offense skill
        [int]$Strength, # Player strength
        [int]$DuelWieldSkill     # Dual Wield skill
    )

    # Get the damage cap based on player level and character type
    $CharacterType = Get-CharacterType -class $Class
    $DamageCap = Get-DamageCapForLevelAndType -level $Level -characterType $CharacterType

    # Initialize an empty results array
    $results = @()

    foreach ($weapon in $Weapons) {
        # Parse weapon damage and delay as integers
        $Damage = [int]$weapon.Dmg
        $Delay = [int]$weapon.Delay

        # Adjust strength with the weapon's strength bonus
        $TotalStrength = $Strength + $weapon.StrengthBonus

        # Get the max DPS for the weapon
        $maxDPSResult = Get-DPSData -Level $Level -OffenseSkill $OffenseSkill -Strength $TotalStrength -WeaponType $weapon.Type -Damage $Damage -Delay $Delay -DamageCap $DamageCap -DuelWieldSkill $DuelWieldSkill
     
        # Create a result object for this weapon
        $result = [WeaponDPSResult]::new()
        $result.WeaponName = $weapon.Name
        $result.Type = $weapon.Type
        $result.MainHandDPS = $maxDPSResult.MainHandDPS
        $result.OffHandDPS = $maxDPSResult.OffHandDPS     
        $result.Damage = $Damage
        $result.Delay = $Delay
        $result.MainHandDamage = $maxDPSResult.MainHandDamage
        $result.OffHandDamage = $maxDPSResult.OffHandDamage
        $result.MainHandBonus = $maxDPSResult.MainHandBonus
        $result.Mod = $maxDPSResult.Mod
        $result.MainHandDmgUncapped = $maxDPSResult.MainHandDmgUncapped

        # Add the result to the collection
        $results += $result
    }

    #Save the values for future display
    $Script:Class = $Class
    $Script:Level = $Level
    $Script:ClassType = $CharacterType
    $Script:OffenseSkill = $OffenseSkill
    $Script:DuelWieldSkill =$DuelWieldSkill
    $Script:Strength = $Strength
    $Script:DamageCap = $DamageCap

    # Return the results sorted by MainHandDPS
    return $results
}




function Get-WeaponsDPSFromString {
    param (
        [string]$Weapons, # String of WeaponData
        [string]$Class, # Character class as a string
        [int]$Level, # Player level
        [int]$OffenseSkill, # Offense skill value
        [int]$Strength, # Strength value
        [int]$DuelWieldSkill          # Duel Wield skill level
    )

    # Create the array of WeaponData objects
    $weaponsArray = New-WeaponArray $Weapons

    # Call the function
    $results = Get-WeaponsDPS -Weapons $weaponsArray -Class $Class -Level $Level -OffenseSkill $OffenseSkill -Strength $Strength -DuelWieldSkill $DuelWieldSkill

    return $results
}


#######################################################################################################################################################################################
# Outputting the results

function Out-Stats(){
    "Class: $Script:Class"
    "Level: $Script:Level"
    "Offense: $Script:OffenseSkill"
    "Strength: $Script:Strength"
    "Duel Wield: $Script:DuelWieldSkill"
    "Damage Cap: $Script:DamageCap ($Script:ClassType)"
}



function Out-WeaponDPSResultsShort {
    param (
        [array]$Results  # Array of weapon DPS results
    )

    # Output the results sorted by Main Hand DPS
    $Results | Sort-Object Type, MainHandDPS | ForEach-Object {
        [PSCustomObject]@{
            'Weapon Name'   = $_.WeaponName
            'Type '         = $_.Type
            'Main Hand DPS' = "{0,13:N2}" -f $_.MainHandDPS
            'Off Hand DPS'  = if ($_.OffHandDPS -eq 0) { "" } else { "{0,12:N2}" -f $_.OffHandDPS }
        }
    } | Format-Table -AutoSize
}



function Out-WeaponDPSResultsFull {
    param (
        [WeaponDPSResult[]]$results  # Array of WeaponDPSResult objects
    )

    # Output the sorted results in a tabular format, including the intermediate fields
    $results | Sort-Object Type, MainHandDPS | ForEach-Object {
        [PSCustomObject]@{
            'Weapon Name'   = $_.WeaponName
            'Type '         = $_.Type
            'Main Hand DPS' = $_.MainHandDPS
            'Off Hand DPS'  = if ($_.OffHandDPS -eq 0) { "" } else { "{0,12:N2}" -f $_.OffHandDPS }  # Blank if 0.00
            'Damage/Delay'  = "{0,12}" -f -join ($_.Damage, "/", $_.Delay)
            'Main Hand Dmg' = $_.MainHandDamage
            'Off Hand Dmg'  = if ($_.OffHandDamage -eq 0) { "" } else { "{0,12:N0}" -f $_.OffHandDamage }  # Blank if 0.00
            'Uncapped Dmg'  = "{0,12}" -f $( if($_.MainHandDmgUncapped -ne $_.MainHandDamage) {$_.MainHandDmgUncapped } else {""} )
            'Dmg Bonus'     = $_.MainHandBonus
            'Attack Mod'    = $_.Mod
        }
    } | Format-Table -AutoSize 
}


function Out-WeaponDPSResults {
    param (
        [array]$Results,  # Array of weapon DPS results
        [switch] $Debug
   )

   Out-Stats
   Write-Host

   if($debug.IsPresent){
     Out-WeaponDPSResultsFull $results
   }
   else {
     Out-WeaponDPSResultsShort $results
   }
}

#######################################################################################################################################################################################
# TODO

<#
Double Attack
(% Chance to Double Attack Per Hit) = (Double Attack Skill Level) / ("MaxSkill"*1.05)
The value of "MaxSkill" may be ~400 (unconfirmed)

-does this affect offhand?

Haste:

Weapon Skills:
No idea how this afffects things
#>