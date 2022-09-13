/*
    Script: ef_i_convert.nss
    Author: Daz

    Description: Equinox Framework Conversion Include
*/

int EffectIconToEffectType(int nEffectIcon);
int AbilityTypeFromEffectIconAbility(int nEffectIcon);
int DamageTypeFromEffectIconDamageImmunity(int nEffectIcon);
int ImmunityTypeFromEffectIconImmunity(int nEffectIcon);
string ACTypeToString(int nACType);
string SavingThrowToString(int nSavingThrow);
string SavingThrowTypeToString(int nSavingThrowType);
string AbilityToString(int nAbility);
string DamageTypeToString(int nDamageType);
string SpellSchoolToString(int nSpellSchool);
string MissChanceToString(int nMissChance);
string ObjectTypeToString(int nObjectType);
int MetaMagicConstantTo2DARow(int nMetaMagic);
int AbilityToConstant(string sStringAbility);
string AbilityConstantToName(int nAbility);

int EffectIconToEffectType(int nEffectIcon)
{
    switch (nEffectIcon)
    {
        case EFFECT_ICON_INVALID:                           return EFFECT_TYPE_INVALIDEFFECT;

        case EFFECT_ICON_BLIND:                             return EFFECT_TYPE_BLINDNESS;
        case EFFECT_ICON_CHARMED:                           return EFFECT_TYPE_CHARMED;
        case EFFECT_ICON_CONFUSED:                          return EFFECT_TYPE_CONFUSED;
        case EFFECT_ICON_FRIGHTENED:                        return EFFECT_TYPE_FRIGHTENED;
        case EFFECT_ICON_DOMINATED:                         return EFFECT_TYPE_DOMINATED;
        case EFFECT_ICON_PARALYZE:                          return EFFECT_TYPE_PARALYZE;
        case EFFECT_ICON_DAZED:                             return EFFECT_TYPE_DAZED;
        case EFFECT_ICON_STUNNED:                           return EFFECT_TYPE_STUNNED;
        case EFFECT_ICON_SLEEP:                             return EFFECT_TYPE_SLEEP;
        case EFFECT_ICON_SILENCE:                           return EFFECT_TYPE_SILENCE;
        case EFFECT_ICON_TURNED:                            return EFFECT_TYPE_TURNED;
        case EFFECT_ICON_HASTE:                             return EFFECT_TYPE_HASTE;
        case EFFECT_ICON_SLOW:                              return EFFECT_TYPE_SLOW;
        case EFFECT_ICON_ENTANGLE:                          return EFFECT_TYPE_ENTANGLE;
        case EFFECT_ICON_DEAF:                              return EFFECT_TYPE_DEAF;
        case EFFECT_ICON_DARKNESS:                          return EFFECT_TYPE_DARKNESS;
        case EFFECT_ICON_POLYMORPH:                         return EFFECT_TYPE_POLYMORPH;
        case EFFECT_ICON_SANCTUARY:                         return EFFECT_TYPE_SANCTUARY;
        case EFFECT_ICON_TRUESEEING:                        return EFFECT_TYPE_TRUESEEING;
        case EFFECT_ICON_SEEINVISIBILITY:                   return EFFECT_TYPE_SEEINVISIBLE;
        case EFFECT_ICON_ETHEREALNESS:                      return EFFECT_TYPE_ETHEREAL;

        case EFFECT_ICON_DAMAGE_RESISTANCE:                 return EFFECT_TYPE_DAMAGE_RESISTANCE;
        case EFFECT_ICON_REGENERATE:                        return EFFECT_TYPE_REGENERATE;
        case EFFECT_ICON_DAMAGE_REDUCTION:                  return EFFECT_TYPE_DAMAGE_REDUCTION;
        case EFFECT_ICON_TEMPORARY_HITPOINTS:               return EFFECT_TYPE_TEMPORARY_HITPOINTS;
        case EFFECT_ICON_IMMUNITY:                          return EFFECT_TYPE_IMMUNITY;
        case EFFECT_ICON_POISON:                            return EFFECT_TYPE_POISON;
        case EFFECT_ICON_DISEASE:                           return EFFECT_TYPE_DISEASE;
        case EFFECT_ICON_CURSE:                             return EFFECT_TYPE_CURSE;
        case EFFECT_ICON_ATTACK_INCREASE:                   return EFFECT_TYPE_ATTACK_INCREASE;
        case EFFECT_ICON_ATTACK_DECREASE:                   return EFFECT_TYPE_ATTACK_DECREASE;
        case EFFECT_ICON_DAMAGE_INCREASE:                   return EFFECT_TYPE_DAMAGE_INCREASE;
        case EFFECT_ICON_DAMAGE_DECREASE:                   return EFFECT_TYPE_DAMAGE_DECREASE;
        case EFFECT_ICON_AC_INCREASE:                       return EFFECT_TYPE_AC_INCREASE;
        case EFFECT_ICON_AC_DECREASE:                       return EFFECT_TYPE_AC_DECREASE;
        case EFFECT_ICON_MOVEMENT_SPEED_INCREASE:           return EFFECT_TYPE_MOVEMENT_SPEED_INCREASE;
        case EFFECT_ICON_MOVEMENT_SPEED_DECREASE:           return EFFECT_TYPE_MOVEMENT_SPEED_DECREASE;
        case EFFECT_ICON_SAVING_THROW_DECREASE:             return EFFECT_TYPE_SAVING_THROW_DECREASE;
        case EFFECT_ICON_SPELL_RESISTANCE_INCREASE:         return EFFECT_TYPE_SPELL_RESISTANCE_INCREASE;
        case EFFECT_ICON_SPELL_RESISTANCE_DECREASE:         return EFFECT_TYPE_SPELL_RESISTANCE_DECREASE;
        case EFFECT_ICON_SKILL_INCREASE:                    return EFFECT_TYPE_SKILL_INCREASE;
        case EFFECT_ICON_SKILL_DECREASE:                    return EFFECT_TYPE_SKILL_DECREASE;
        case EFFECT_ICON_ELEMENTALSHIELD:                   return EFFECT_TYPE_ELEMENTALSHIELD;
        case EFFECT_ICON_LEVELDRAIN:                        return EFFECT_TYPE_NEGATIVELEVEL;
        case EFFECT_ICON_SPELLLEVELABSORPTION:              return EFFECT_TYPE_SPELLLEVELABSORPTION;
        case EFFECT_ICON_SPELLIMMUNITY:                     return EFFECT_TYPE_SPELL_IMMUNITY;
        case EFFECT_ICON_CONCEALMENT:                       return EFFECT_TYPE_CONCEALMENT;
        case EFFECT_ICON_EFFECT_SPELL_FAILURE:              return EFFECT_TYPE_SPELL_FAILURE;

        case EFFECT_ICON_INVISIBILITY:
        case EFFECT_ICON_IMPROVEDINVISIBILITY:              return EFFECT_TYPE_INVISIBILITY;

        case EFFECT_ICON_ABILITY_INCREASE_STR:
        case EFFECT_ICON_ABILITY_INCREASE_DEX:
        case EFFECT_ICON_ABILITY_INCREASE_CON:
        case EFFECT_ICON_ABILITY_INCREASE_INT:
        case EFFECT_ICON_ABILITY_INCREASE_WIS:
        case EFFECT_ICON_ABILITY_INCREASE_CHA:              return EFFECT_TYPE_ABILITY_INCREASE;

        case EFFECT_ICON_ABILITY_DECREASE_STR:
        case EFFECT_ICON_ABILITY_DECREASE_CHA:
        case EFFECT_ICON_ABILITY_DECREASE_DEX:
        case EFFECT_ICON_ABILITY_DECREASE_CON:
        case EFFECT_ICON_ABILITY_DECREASE_INT:
        case EFFECT_ICON_ABILITY_DECREASE_WIS:              return EFFECT_TYPE_ABILITY_DECREASE;

        case EFFECT_ICON_IMMUNITY_ALL:
        case EFFECT_ICON_IMMUNITY_MIND:
        case EFFECT_ICON_IMMUNITY_POISON:
        case EFFECT_ICON_IMMUNITY_DISEASE:
        case EFFECT_ICON_IMMUNITY_FEAR:
        case EFFECT_ICON_IMMUNITY_TRAP:
        case EFFECT_ICON_IMMUNITY_PARALYSIS:
        case EFFECT_ICON_IMMUNITY_BLINDNESS:
        case EFFECT_ICON_IMMUNITY_DEAFNESS:
        case EFFECT_ICON_IMMUNITY_SLOW:
        case EFFECT_ICON_IMMUNITY_ENTANGLE:
        case EFFECT_ICON_IMMUNITY_SILENCE:
        case EFFECT_ICON_IMMUNITY_STUN:
        case EFFECT_ICON_IMMUNITY_SLEEP:
        case EFFECT_ICON_IMMUNITY_CHARM:
        case EFFECT_ICON_IMMUNITY_DOMINATE:
        case EFFECT_ICON_IMMUNITY_CONFUSE:
        case EFFECT_ICON_IMMUNITY_CURSE:
        case EFFECT_ICON_IMMUNITY_DAZED:
        case EFFECT_ICON_IMMUNITY_ABILITY_DECREASE:
        case EFFECT_ICON_IMMUNITY_ATTACK_DECREASE:
        case EFFECT_ICON_IMMUNITY_DAMAGE_DECREASE:
        case EFFECT_ICON_IMMUNITY_DAMAGE_IMMUNITY_DECREASE:
        case EFFECT_ICON_IMMUNITY_AC_DECREASE:
        case EFFECT_ICON_IMMUNITY_MOVEMENT_SPEED_DECREASE:
        case EFFECT_ICON_IMMUNITY_SAVING_THROW_DECREASE:
        case EFFECT_ICON_IMMUNITY_SPELL_RESISTANCE_DECREASE:
        case EFFECT_ICON_IMMUNITY_SKILL_DECREASE:
        case EFFECT_ICON_IMMUNITY_KNOCKDOWN:
        case EFFECT_ICON_IMMUNITY_NEGATIVE_LEVEL:
        case EFFECT_ICON_IMMUNITY_SNEAK_ATTACK:
        case EFFECT_ICON_IMMUNITY_CRITICAL_HIT:
        case EFFECT_ICON_IMMUNITY_DEATH_MAGIC:              return EFFECT_TYPE_IMMUNITY;

        case EFFECT_ICON_SAVING_THROW_INCREASE:
        case EFFECT_ICON_REFLEX_SAVE_INCREASED:
        case EFFECT_ICON_FORT_SAVE_INCREASED:
        case EFFECT_ICON_WILL_SAVE_INCREASED:               return EFFECT_TYPE_SAVING_THROW_INCREASE;

        case EFFECT_ICON_DAMAGE_IMMUNITY_INCREASE:
        case EFFECT_ICON_DAMAGE_IMMUNITY_MAGIC:
        case EFFECT_ICON_DAMAGE_IMMUNITY_ACID:
        case EFFECT_ICON_DAMAGE_IMMUNITY_COLD:
        case EFFECT_ICON_DAMAGE_IMMUNITY_DIVINE:
        case EFFECT_ICON_DAMAGE_IMMUNITY_ELECTRICAL:
        case EFFECT_ICON_DAMAGE_IMMUNITY_FIRE:
        case EFFECT_ICON_DAMAGE_IMMUNITY_NEGATIVE:
        case EFFECT_ICON_DAMAGE_IMMUNITY_POSITIVE:
        case EFFECT_ICON_DAMAGE_IMMUNITY_SONIC:             return EFFECT_TYPE_DAMAGE_IMMUNITY_INCREASE;

       case EFFECT_ICON_DAMAGE_IMMUNITY_DECREASE:
        case EFFECT_ICON_DAMAGE_IMMUNITY_MAGIC_DECREASE:
        case EFFECT_ICON_DAMAGE_IMMUNITY_ACID_DECREASE:
        case EFFECT_ICON_DAMAGE_IMMUNITY_COLD_DECREASE:
        case EFFECT_ICON_DAMAGE_IMMUNITY_DIVINE_DECREASE:
        case EFFECT_ICON_DAMAGE_IMMUNITY_ELECTRICAL_DECREASE:
        case EFFECT_ICON_DAMAGE_IMMUNITY_FIRE_DECREASE:
        case EFFECT_ICON_DAMAGE_IMMUNITY_NEGATIVE_DECREASE:
        case EFFECT_ICON_DAMAGE_IMMUNITY_POSITIVE_DECREASE:
        case EFFECT_ICON_DAMAGE_IMMUNITY_SONIC_DECREASE:    return EFFECT_TYPE_DAMAGE_IMMUNITY_DECREASE;

        //case EFFECT_ICON_INVULNERABLE: return EFFECT_TYPE_INVULNERABLE;
        //case EFFECT_ICON_WOUNDING: return EFFECT_TYPE_INVALIDEFFECT;
        //case EFFECT_ICON_TAUNTED: return EFFECT_TYPE_INVALIDEFFECT;
        //case EFFECT_ICON_TIMESTOP: return EFFECT_TYPE_TIMESTOP;
        //case EFFECT_ICON_BLINDNESS: return EFFECT_TYPE_BLINDNESS;
        //case EFFECT_ICON_DISPELMAGICBEST: return EFFECT_TYPE_INVALIDEFFECT;
        //case EFFECT_ICON_DISPELMAGICALL: return EFFECT_TYPE_INVALIDEFFECT;
        //case EFFECT_ICON_ENEMY_ATTACK_BONUS: return EFFECT_TYPE_INVALIDEFFECT;
        //case EFFECT_ICON_FATIGUE: return EFFECT_TYPE_INVALIDEFFECT;
    }

    return EFFECT_TYPE_INVALIDEFFECT;
}

int AbilityTypeFromEffectIconAbility(int nEffectIcon)
{
    switch (nEffectIcon)
    {
        case EFFECT_ICON_ABILITY_INCREASE_STR:
        case EFFECT_ICON_ABILITY_DECREASE_STR:
            return ABILITY_STRENGTH;
        case EFFECT_ICON_ABILITY_INCREASE_DEX:
        case EFFECT_ICON_ABILITY_DECREASE_DEX:
            return ABILITY_DEXTERITY;
        case EFFECT_ICON_ABILITY_INCREASE_CON:
        case EFFECT_ICON_ABILITY_DECREASE_CON:
            return ABILITY_CONSTITUTION;
        case EFFECT_ICON_ABILITY_INCREASE_INT:
        case EFFECT_ICON_ABILITY_DECREASE_INT:
            return ABILITY_INTELLIGENCE;
        case EFFECT_ICON_ABILITY_INCREASE_WIS:
        case EFFECT_ICON_ABILITY_DECREASE_WIS:
            return ABILITY_WISDOM;
        case EFFECT_ICON_ABILITY_INCREASE_CHA:
        case EFFECT_ICON_ABILITY_DECREASE_CHA:
            return ABILITY_CHARISMA;
    }

    return -1;
}

int DamageTypeFromEffectIconDamageImmunity(int nEffectIcon)
{
    switch (nEffectIcon)
    {
        case EFFECT_ICON_DAMAGE_IMMUNITY_MAGIC:
        case EFFECT_ICON_DAMAGE_IMMUNITY_MAGIC_DECREASE:
            return DAMAGE_TYPE_MAGICAL;
        case EFFECT_ICON_DAMAGE_IMMUNITY_ACID:
        case EFFECT_ICON_DAMAGE_IMMUNITY_ACID_DECREASE:
            return DAMAGE_TYPE_ACID;
        case EFFECT_ICON_DAMAGE_IMMUNITY_COLD:
        case EFFECT_ICON_DAMAGE_IMMUNITY_COLD_DECREASE:
            return DAMAGE_TYPE_COLD;
        case EFFECT_ICON_DAMAGE_IMMUNITY_DIVINE:
        case EFFECT_ICON_DAMAGE_IMMUNITY_DIVINE_DECREASE:
            return DAMAGE_TYPE_DIVINE;
        case EFFECT_ICON_DAMAGE_IMMUNITY_ELECTRICAL:
        case EFFECT_ICON_DAMAGE_IMMUNITY_ELECTRICAL_DECREASE:
            return DAMAGE_TYPE_ELECTRICAL;
        case EFFECT_ICON_DAMAGE_IMMUNITY_FIRE:
        case EFFECT_ICON_DAMAGE_IMMUNITY_FIRE_DECREASE:
            return DAMAGE_TYPE_FIRE;
        case EFFECT_ICON_DAMAGE_IMMUNITY_NEGATIVE:
        case EFFECT_ICON_DAMAGE_IMMUNITY_NEGATIVE_DECREASE:
            return DAMAGE_TYPE_NEGATIVE;
        case EFFECT_ICON_DAMAGE_IMMUNITY_POSITIVE:
        case EFFECT_ICON_DAMAGE_IMMUNITY_POSITIVE_DECREASE:
            return DAMAGE_TYPE_POSITIVE;
        case EFFECT_ICON_DAMAGE_IMMUNITY_SONIC:
        case EFFECT_ICON_DAMAGE_IMMUNITY_SONIC_DECREASE:
            return DAMAGE_TYPE_SONIC;
    }

    return -1;
}

int ImmunityTypeFromEffectIconImmunity(int nEffectIcon)
{
    switch (nEffectIcon)
    {
        case EFFECT_ICON_IMMUNITY_MIND:                         return IMMUNITY_TYPE_MIND_SPELLS;
        case EFFECT_ICON_IMMUNITY_POISON:                       return IMMUNITY_TYPE_POISON;
        case EFFECT_ICON_IMMUNITY_DISEASE:                      return IMMUNITY_TYPE_DISEASE;
        case EFFECT_ICON_IMMUNITY_FEAR:                         return IMMUNITY_TYPE_FEAR;
        case EFFECT_ICON_IMMUNITY_TRAP:                         return IMMUNITY_TYPE_TRAP;
        case EFFECT_ICON_IMMUNITY_PARALYSIS:                    return IMMUNITY_TYPE_PARALYSIS;
        case EFFECT_ICON_IMMUNITY_BLINDNESS:                    return IMMUNITY_TYPE_BLINDNESS;
        case EFFECT_ICON_IMMUNITY_DEAFNESS:                     return IMMUNITY_TYPE_DEAFNESS;
        case EFFECT_ICON_IMMUNITY_SLOW:                         return IMMUNITY_TYPE_SLOW;
        case EFFECT_ICON_IMMUNITY_ENTANGLE:                     return IMMUNITY_TYPE_ENTANGLE;
        case EFFECT_ICON_IMMUNITY_SILENCE:                      return IMMUNITY_TYPE_SILENCE;
        case EFFECT_ICON_IMMUNITY_STUN:                         return IMMUNITY_TYPE_STUN;
        case EFFECT_ICON_IMMUNITY_SLEEP:                        return IMMUNITY_TYPE_SLEEP;
        case EFFECT_ICON_IMMUNITY_CHARM:                        return IMMUNITY_TYPE_CHARM;
        case EFFECT_ICON_IMMUNITY_DOMINATE:                     return IMMUNITY_TYPE_DOMINATE;
        case EFFECT_ICON_IMMUNITY_CONFUSE:                      return IMMUNITY_TYPE_CONFUSED;
        case EFFECT_ICON_IMMUNITY_CURSE:                        return IMMUNITY_TYPE_CURSED;
        case EFFECT_ICON_IMMUNITY_DAZED:                        return IMMUNITY_TYPE_DAZED;
        case EFFECT_ICON_IMMUNITY_ABILITY_DECREASE:             return IMMUNITY_TYPE_ABILITY_DECREASE;
        case EFFECT_ICON_IMMUNITY_ATTACK_DECREASE:              return IMMUNITY_TYPE_ATTACK_DECREASE;
        case EFFECT_ICON_IMMUNITY_DAMAGE_DECREASE:              return IMMUNITY_TYPE_DAMAGE_DECREASE;
        case EFFECT_ICON_IMMUNITY_DAMAGE_IMMUNITY_DECREASE:     return IMMUNITY_TYPE_DAMAGE_IMMUNITY_DECREASE;
        case EFFECT_ICON_IMMUNITY_AC_DECREASE:                  return IMMUNITY_TYPE_AC_DECREASE;
        case EFFECT_ICON_IMMUNITY_MOVEMENT_SPEED_DECREASE:      return IMMUNITY_TYPE_MOVEMENT_SPEED_DECREASE;
        case EFFECT_ICON_IMMUNITY_SAVING_THROW_DECREASE:        return IMMUNITY_TYPE_SAVING_THROW_DECREASE;
        case EFFECT_ICON_IMMUNITY_SPELL_RESISTANCE_DECREASE:    return IMMUNITY_TYPE_SPELL_RESISTANCE_DECREASE;
        case EFFECT_ICON_IMMUNITY_SKILL_DECREASE:               return IMMUNITY_TYPE_SKILL_DECREASE;
        case EFFECT_ICON_IMMUNITY_KNOCKDOWN:                    return IMMUNITY_TYPE_KNOCKDOWN;
        case EFFECT_ICON_IMMUNITY_NEGATIVE_LEVEL:               return IMMUNITY_TYPE_NEGATIVE_LEVEL;
        case EFFECT_ICON_IMMUNITY_SNEAK_ATTACK:                 return IMMUNITY_TYPE_SNEAK_ATTACK;
        case EFFECT_ICON_IMMUNITY_CRITICAL_HIT:                 return IMMUNITY_TYPE_CRITICAL_HIT;
        case EFFECT_ICON_IMMUNITY_DEATH_MAGIC:                  return IMMUNITY_TYPE_DEATH;
    }

    return -1;
}

string ACTypeToString(int nACType)
{
    switch (nACType)
    {
        case AC_DODGE_BONUS:                return "Dodge";
        case AC_NATURAL_BONUS:              return "Natural";
        case AC_ARMOUR_ENCHANTMENT_BONUS:   return "Armor";
        case AC_SHIELD_ENCHANTMENT_BONUS:   return "Shield";
        case AC_DEFLECTION_BONUS:           return "Deflection";
    }

    return "";
}

string SavingThrowToString(int nSavingThrow)
{
    switch (nSavingThrow)
    {
        case SAVING_THROW_ALL:      return "All";
        case SAVING_THROW_FORT:     return "Fortitude";
        case SAVING_THROW_REFLEX:   return "Reflex";
        case SAVING_THROW_WILL:     return "Will";
    }

    return "";
}

string SavingThrowTypeToString(int nSavingThrowType)
{
    switch (nSavingThrowType)
    {
        case SAVING_THROW_TYPE_MIND_SPELLS:     return "Mind Spells";
        case SAVING_THROW_TYPE_POISON:          return "Poison";
        case SAVING_THROW_TYPE_DISEASE:         return "Disease";
        case SAVING_THROW_TYPE_FEAR:            return "Fear";
        case SAVING_THROW_TYPE_SONIC:           return "Sonic";
        case SAVING_THROW_TYPE_ACID:            return "Acid";
        case SAVING_THROW_TYPE_FIRE:            return "Fire";
        case SAVING_THROW_TYPE_ELECTRICITY:     return "Electricity";
        case SAVING_THROW_TYPE_POSITIVE:        return "Positive";
        case SAVING_THROW_TYPE_NEGATIVE:        return "Negative";
        case SAVING_THROW_TYPE_DEATH:           return "Death";
        case SAVING_THROW_TYPE_COLD:            return "Cold";
        case SAVING_THROW_TYPE_DIVINE:          return "Divine";
        case SAVING_THROW_TYPE_TRAP:            return "Traps";
        case SAVING_THROW_TYPE_SPELL:           return "Spells";
        case SAVING_THROW_TYPE_GOOD:            return "Good";
        case SAVING_THROW_TYPE_EVIL:            return "Evil";
        case SAVING_THROW_TYPE_LAW:             return "Lawful";
        case SAVING_THROW_TYPE_CHAOS:           return "Chaotic";
    }

    return "";
}

string AbilityToString(int nAbility)
{
    switch (nAbility)
    {
        case ABILITY_STRENGTH:      return "Strength";
        case ABILITY_DEXTERITY:     return "Dexterity";
        case ABILITY_CONSTITUTION:  return "Constitution";
        case ABILITY_INTELLIGENCE:  return "Intelligence";
        case ABILITY_WISDOM:        return "Wisdom";
        case ABILITY_CHARISMA:      return "Charisma";
    }

    return "";
}

string DamageTypeToString(int nDamageType)
{
    switch (nDamageType)
    {
        case DAMAGE_TYPE_BLUDGEONING:   return "Bludgeoning";
        case DAMAGE_TYPE_PIERCING:      return "Piercing";
        case DAMAGE_TYPE_SLASHING:      return "Slashing";
        case DAMAGE_TYPE_MAGICAL:       return "Magical";
        case DAMAGE_TYPE_ACID:          return "Acid";
        case DAMAGE_TYPE_COLD:          return "Cold";
        case DAMAGE_TYPE_DIVINE:        return "Divine";
        case DAMAGE_TYPE_ELECTRICAL:    return "Electrical";
        case DAMAGE_TYPE_FIRE:          return "Fire";
        case DAMAGE_TYPE_NEGATIVE:      return "Negative";
        case DAMAGE_TYPE_POSITIVE:      return "Positive";
        case DAMAGE_TYPE_SONIC:         return "Sonic";
        case DAMAGE_TYPE_BASE_WEAPON:   return "Base Weapon";
    }

    return "";
}

string SpellSchoolToString(int nSpellSchool)
{
    switch (nSpellSchool)
    {
        case SPELL_SCHOOL_GENERAL:          return "General";
        case SPELL_SCHOOL_ABJURATION:       return "Abjuration";
        case SPELL_SCHOOL_CONJURATION:      return "Conjuration";
        case SPELL_SCHOOL_DIVINATION:       return "Divination";
        case SPELL_SCHOOL_ENCHANTMENT:      return "Enchantment";
        case SPELL_SCHOOL_EVOCATION:        return "Evocation";
        case SPELL_SCHOOL_ILLUSION:         return "Illusion";
        case SPELL_SCHOOL_NECROMANCY:       return "Necromancy";
        case SPELL_SCHOOL_TRANSMUTATION:    return "Transmutation";
    }

    return "";
}

string MissChanceToString(int nMissChance)
{
    switch (nMissChance)
    {
        case MISS_CHANCE_TYPE_VS_RANGED: return "vs. Ranged";
        case MISS_CHANCE_TYPE_VS_MELEE: return "vs. Melee";
    }

    return "";
}

string ObjectTypeToString(int nObjectType)
{
    switch (nObjectType)
    {
        case OBJECT_TYPE_AREA_OF_EFFECT:    return "AreaOfEffect";
        case OBJECT_TYPE_CREATURE:          return "Creature";
        case OBJECT_TYPE_DOOR:              return "Door";
        case OBJECT_TYPE_ENCOUNTER:         return "Encounter";
        case OBJECT_TYPE_ITEM:              return "Item";
        case OBJECT_TYPE_PLACEABLE:         return "Placeable";
        case OBJECT_TYPE_STORE:             return "Store";
        case OBJECT_TYPE_TRIGGER:           return "Trigger";
        case OBJECT_TYPE_WAYPOINT:          return "Waypoint";
    }

    return "Unknown";
}

int MetaMagicConstantTo2DARow(int nMetaMagic)
{
    switch (nMetaMagic)
    {
        case METAMAGIC_QUICKEN:
            return 1;
        case METAMAGIC_EMPOWER:
            return 2;
        case METAMAGIC_EXTEND:
            return 3;
        case METAMAGIC_MAXIMIZE:
            return 4;
        case METAMAGIC_SILENT:
            return 5;
        case METAMAGIC_STILL:
            return 6;
    }

    return 0;
}

int AbilityToConstant(string sStringAbility)
{
    string sAbility = GetStringLowerCase(sStringAbility);
    if (sAbility == "str")
        return ABILITY_STRENGTH;
    if (sAbility == "dex")
        return ABILITY_DEXTERITY;
    if (sAbility == "con")
        return ABILITY_CONSTITUTION;
    if (sAbility == "int")
        return ABILITY_INTELLIGENCE;
    if (sAbility == "wis")
        return ABILITY_WISDOM;
    if (sAbility == "cha")
        return ABILITY_CHARISMA;

    return -1;// :|
}

string AbilityConstantToName(int nAbility)
{
    if (nAbility == ABILITY_STRENGTH)
        return "Strength";
    if (nAbility == ABILITY_DEXTERITY)
        return "Dexterity";
    if (nAbility == ABILITY_CONSTITUTION)
        return "Consitution";
    if (nAbility == ABILITY_INTELLIGENCE)
        return "Intelligence";
    if (nAbility == ABILITY_WISDOM)
        return "Wisdom";
    if (nAbility == ABILITY_CHARISMA)
        return "Charisma";

    return "";
}

