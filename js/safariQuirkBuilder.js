function _scanSetFromCharacterClass(characterClass)
{
    if (characterClass instanceof CustomCharacterClass)
        return characterClass.characters;
    console.assert(characterClass instanceof NamedCharacterClass);
    switch (characterClass.name) {
    case Identifier.ASCII_PRINTABLE:
    case Identifier.UNICODE:
        return SCAN_SET_ORDER.split("");
    case Identifier.DIGIT:
        return SCAN_SET_ORDER.substring(SCAN_SET_ORDER.indexOf("0"), SCAN_SET_ORDER.indexOf("9") + 1).split("");
    case Identifier.LOWER:
        return SCAN_SET_ORDER.substring(SCAN_SET_ORDER.indexOf("a"), SCAN_SET_ORDER.indexOf("z") + 1).split("");
    case Identifier.SPECIAL:
        return SCAN_SET_ORDER.substring(SCAN_SET_ORDER.indexOf("-"), SCAN_SET_ORDER.indexOf("]") + 1).split("");
    case Identifier.UPPER:
        return SCAN_SET_ORDER.substring(SCAN_SET_ORDER.indexOf("A"), SCAN_SET_ORDER.indexOf("Z") + 1).split("");
    }
    console.assert(false, SHOULD_NOT_BE_REACHED);
}

function _charactersFromCharactersClasses(characterClasses)
{
    return characterClasses.reduce((scanSet, currentCharacterClass) => scanSet.concat(_scanSetFromCharacterClass(currentCharacterClass)), []);
}

const SCAN_SET_ORDER = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-~!@#$%^&*_+=`|(){}[:;\\\"'<>,.?/ ]";

function _canonicalizedScanSetFromCharacters(characters)
{
    if (!characters.length)
        return "";
    let shadowCharacters = Array.prototype.slice.call(characters); // Make a copy so that we do not mutate |characters|.
    shadowCharacters.sort((a, b) => SCAN_SET_ORDER.indexOf(a) - SCAN_SET_ORDER.indexOf(b));
    let uniqueCharacters = [shadowCharacters[0]];
    for (let i = 1, length = shadowCharacters.length; i < length; ++i) {
        if (shadowCharacters[i] === shadowCharacters[i - 1])
            continue;
        uniqueCharacters.push(shadowCharacters[i]);
    }
    return uniqueCharacters.join("");
}

function safariQuirkFromPasswordRules(input)
{
    let result = { };
    let passwordRules = parsePasswordRules(input);
    for (let rule of passwordRules) {
        if (rule.name === RuleName.ALLOWED) {
            console.assert(!("PasswordAllowedCharacters" in result));
            let scanSet = _canonicalizedScanSetFromCharacters(_charactersFromCharactersClasses(rule.value));
            if (scanSet)
                result["PasswordAllowedCharacters"] = scanSet;
        } else if (rule.name === RuleName.MAX_CONSECUTIVE) {
            console.assert(!("PasswordRepeatedCharacterLimit" in result));
            result["PasswordRepeatedCharacterLimit"] = rule.value;
        } else if (rule.name === RuleName.REQUIRED) {
            let requiredCharacters = result["PasswordRequiredCharacters"];
            if (!requiredCharacters)
                requiredCharacters = result["PasswordRequiredCharacters"] = [];
            requiredCharacters.push(_canonicalizedScanSetFromCharacters(_charactersFromCharactersClasses(rule.value)));
        } else if (rule.name === RuleName.MIN_LENGTH) {
            result["PasswordMinLength"] = rule.value;
        } else if (rule.name === RuleName.MAX_LENGTH) {
            result["PasswordMaxLength"] = rule.value;
        }
    }

    // Only include an allowed rule matching SCAN_SET_ORDER (all characters) when a required rule is also present.
    if (result["PasswordAllowedCharacters"] == SCAN_SET_ORDER && !result["PasswordRequiredCharacters"])
        delete result["PasswordAllowedCharacters"];

    // Fix up PasswordRequiredCharacters, if needed.
    if (result["PasswordRequiredCharacters"] && result["PasswordRequiredCharacters"].length === 1 && result["PasswordRequiredCharacters"][0] === SCAN_SET_ORDER)
        delete result["PasswordRequiredCharacters"];

    return Object.keys(result).length ? result : null;
}

var FormatAs = {
    HTML: 0,
    UIKit: 1,
};

function minifiedBasePasswordRules(input, formatAsType)
{
    let pieces = []
    let passwordRules = parsePasswordRules(input, true);
    for (rule of passwordRules) {
        let ruleValue;
        if (formatAsType == FormatAs.HTML && (rule.name === RuleName.ALLOWED || rule.name === RuleName.REQUIRED)) {
            ruleValue = rule.value.map((characterClass) => characterClass.toHTMLString());
        } else
            ruleValue = rule.value;
        pieces.push(`${rule.name}: ${ruleValue};`);
    }
    return pieces.join(" ");
}
