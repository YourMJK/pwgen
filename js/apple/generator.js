const defaultUnambiguousCharacters = "abcdefghijkmnopqrstuvwxyzABCDEFGHIJKLMNPQRSTUVWXYZ0123456789";

const defaultNumberOfCharactersForClassicPassword = 12;
const defaultClassicPasswordLength = 15;

const defaultNumberOfCharactersForMoreTypeablePassword = 18;
const defaultMoreTypeablePasswordLength = 20;
const defaultAllowedNumbers = "0123456789";
const defaultAllowedLowercaseConsonants = "bcdfghjkmnpqrstvwxz";
const defaultAllowedLowercaseVowels = "aeiouy";

var PasswordGenerationStyle = {
    Classic: 1,
    ClassicWithoutDashes: 2,
    MoreTypeable: 3,
    MoreTypeableWithoutDashes: 4,
};

function randomNumberWithUniformDistribution(range)
{
    // Based on the algorithn described in https://pthree.org/2018/06/13/why-the-multiply-and-floor-rng-method-is-biased/
    var max = Math.floor(2**32 / range) * range;
    do {
        var x = window.crypto.getRandomValues(new Uint32Array(1))[0];
    } while (x >= max);

    return (x % range);
}

function randomConsonant()
{
    var index = randomNumberWithUniformDistribution(defaultAllowedLowercaseConsonants.length);
    return defaultAllowedLowercaseConsonants[index];
}

function randomVowel()
{
    var index = randomNumberWithUniformDistribution(defaultAllowedLowercaseVowels.length);
    return defaultAllowedLowercaseVowels[index];
}

function randomNumber()
{
    var index = randomNumberWithUniformDistribution(defaultAllowedNumbers.length);
    return defaultAllowedNumbers[index];
}

function randomSyllable()
{
    return randomConsonant() + randomVowel() + randomConsonant();
}

function _moreTypeablePassword()
{
    var password = randomSyllable() + randomSyllable() + randomSyllable() + randomSyllable() + randomSyllable() + randomConsonant() + randomVowel();
    var length = password.length;
    while (true) {
        var index = randomNumberWithUniformDistribution(length);
        var lowercaseChar = password.charAt(index);
        if (lowercaseChar === "o")
            continue;

        var uppercaseChar = lowercaseChar.toUpperCase();
        password = password.substr(0, index) + uppercaseChar + password.substr(index + 1);

        var numberPos = randomNumberWithUniformDistribution(5);
        var passwordSegment1 = password.substr(0, 6);
        var passwordSegment2 = password.substr(6, 6);
        var passwordSegment3 = password.substr(12, 5);
        switch (numberPos) {
        case 0:
            return passwordSegment3 + randomNumber() + passwordSegment1 + passwordSegment2;
        case 1:
            return passwordSegment1 + randomNumber() + passwordSegment3 + passwordSegment2;
        case 2:
            return passwordSegment1 + passwordSegment3 + randomNumber() + passwordSegment2;
        case 3:
            return passwordSegment1 + passwordSegment2 + randomNumber() + passwordSegment3;
        case 4:
            return passwordSegment1 + passwordSegment2 + passwordSegment3 + randomNumber();
        }
    }
}

function _classicPassword(numberOfRequiredRandomCharacters, allowedCharacters)
{
    var length = allowedCharacters.length;
    var randomCharArray = Array(numberOfRequiredRandomCharacters);
    for (var i = 0; i < numberOfRequiredRandomCharacters; i++) {
        var index = randomNumberWithUniformDistribution(length);
        randomCharArray[i] = allowedCharacters[index];
    }
    return randomCharArray.join("");
}

function _passwordHasNotExceededConsecutiveCharLimit(password, consecutiveCharLimit)
{
    var longestConsecutiveCharLength = 1;
    var firstConsecutiveCharIndex = 0;
    // Both "123" or "abc" and "321" or "cba" are considered consecutive.
    var isSequenceAscending;
    for (var i = 1; i < password.length; i++) {
        var currCharCode = password.charCodeAt(i);
        var prevCharCode = password.charCodeAt(i-1);
        if (isSequenceAscending) {
            // If `isSequenceAscending` is defined, then we know that we are in the middle of an existing
            // pattern. Check if the pattern continues based on whether the previous pattern was
            // ascending or descending.
            if ((isSequenceAscending.valueOf() && currCharCode == prevCharCode + 1) || (!isSequenceAscending.valueOf() && currCharCode == prevCharCode - 1))
                continue;

            // Take into account the case when the sequence transitions from descending
            // to ascending.
            if (currCharCode == prevCharCode + 1) {
                firstConsecutiveCharIndex = i - 1;
                isSequenceAscending = Boolean(true);
                continue;
            }

            // Take into account the case when the sequence transitions from ascending
            // to descending.
            if (currCharCode == prevCharCode - 1) {
                firstConsecutiveCharIndex = i - 1;
                isSequenceAscending = Boolean(false);
                continue;
            }

            isSequenceAscending = null;
        } else if (currCharCode == prevCharCode + 1) {
            isSequenceAscending = Boolean(true);
            continue;
        } else if (currCharCode == prevCharCode - 1) {
            isSequenceAscending = Boolean(false);
            continue;
        }

        var currConsecutiveCharLength = i - firstConsecutiveCharIndex;
        if (currConsecutiveCharLength > longestConsecutiveCharLength)
            longestConsecutiveCharLength = currConsecutiveCharLength;

        firstConsecutiveCharIndex = i;
    }

    if (isSequenceAscending) {
        var currConsecutiveCharLength = password.length - firstConsecutiveCharIndex;
        if (currConsecutiveCharLength > longestConsecutiveCharLength)
            longestConsecutiveCharLength = currConsecutiveCharLength;
    }

    return longestConsecutiveCharLength <= consecutiveCharLimit;
}

function _passwordHasNotExceededRepeatedCharLimit(password, repeatedCharLimit)
{
    var longestRepeatedCharLength = 1;
    var lastRepeatedChar = password.charAt(0);
    var lastRepeatedCharIndex = 0;
    for (var i = 1; i < password.length; i++) {
        var currChar = password.charAt(i);
        if (currChar === lastRepeatedChar)
            continue;

        var currRepeatedCharLength = i - lastRepeatedCharIndex;
        if (currRepeatedCharLength > longestRepeatedCharLength)
            longestRepeatedCharLength = currRepeatedCharLength;

        lastRepeatedChar = currChar;
        lastRepeatedCharIndex = i;
    }
    return longestRepeatedCharLength <= repeatedCharLimit;
}

function _passwordContainsRequiredCharacters(password, requiredCharacterSets)
{
    var requiredCharacterSetsLength = requiredCharacterSets.length;
    var passwordLength = password.length;
    for (var i = 0; i < requiredCharacterSetsLength; i++) {
        var requiredCharacterSet = requiredCharacterSets[i];
        var hasRequiredChar = false;
        for (var j = 0; j < passwordLength; j++) {
            var char = password.charAt(j);
            if (requiredCharacterSet.indexOf(char) !== -1) {
                hasRequiredChar = true;
                break;
            }
        }
        if (!hasRequiredChar)
            return false;
    }
    return true;
}

function _defaultRequiredCharacterSets()
{
    return [ "abcdefghijklmnopqrstuvwxyz", "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "0123456789" ];
}

function _stringContainsAllCharactersInString(string1, string2)
{
    var length = string2.length;
    for (var i = 0; i < length; i++) {
        var character = string2.charAt(i);
        if (string1.indexOf(character) === -1)
            return false;
    }
    return true;
}

function _stringsHaveAtLeastOneCommonCharacter(string1, string2)
{
    var string2Length = string2.length;
    for (var i = 0; i < string2Length; i++) {
        var char = string2.charAt(i);
        if (string1.indexOf(char) !== -1)
            return true;
    }

    return false;
}

function _canUseMoreTypeablePasswordFromRequirements(minPasswordLength, maxPasswordLength, allowedCharacters, requiredCharacterSets)
{
    if ((minPasswordLength > defaultMoreTypeablePasswordLength) || (maxPasswordLength && maxPasswordLength < defaultMoreTypeablePasswordLength))
        return false;

    if (allowedCharacters && !_stringContainsAllCharactersInString(allowedCharacters, defaultUnambiguousCharacters))
        return false;

    var requiredCharacterSetsLength = requiredCharacterSets.length;
    if (requiredCharacterSetsLength > defaultMoreTypeablePasswordLength)
        return false;

    // FIXME: This doesn't handle returning false to a password that requires two or more special characters.
    let numberOfDigitsThatAreRequired = 0;
    let numberOfUpperThatAreRequired = 0;
    for (let requiredCharacterSet of requiredCharacterSets) {
        if (requiredCharacterSet === "0123456789")
            numberOfDigitsThatAreRequired++;
        if (requiredCharacterSet === "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
            numberOfUpperThatAreRequired++;
    }

    if (numberOfDigitsThatAreRequired > 1)
        return false;
    if (numberOfUpperThatAreRequired > 1)
        return false;

    var defaultUnambiguousCharactersPlusDash = defaultUnambiguousCharacters + "-";
    for (var i = 0; i < requiredCharacterSetsLength; i++) {
        var requiredCharacterSet = requiredCharacterSets[i];
        if (!_stringsHaveAtLeastOneCommonCharacter(requiredCharacterSet, defaultUnambiguousCharactersPlusDash))
            return false;
    }

    return true;
}

function _passwordGenerationParametersDictionary(requirements)
{
    var minPasswordLength = requirements["PasswordMinLength"];
    var maxPasswordLength = requirements["PasswordMaxLength"];

    if (minPasswordLength > maxPasswordLength) {
        // Resetting invalid value of min length to zero means "ignore min length parameter in password generation".
        minPasswordLength = 0;
    }

    var allowedCharacters = requirements["PasswordAllowedCharacters"];

    var requiredCharacterArray = requirements["PasswordRequiredCharacters"];
    var requiredCharacterSets = _defaultRequiredCharacterSets();
    if (requiredCharacterArray) {
        var mutatedRequiredCharacterSets = [];
        var requiredCharacterArrayLength = requiredCharacterArray.length;
        for (var i = 0; i < requiredCharacterArrayLength; i++) {
            var requiredCharacters = requiredCharacterArray[i];
            if (_stringsHaveAtLeastOneCommonCharacter(requiredCharacters, allowedCharacters))
                mutatedRequiredCharacterSets.push(requiredCharacters);
        }
        requiredCharacterSets = mutatedRequiredCharacterSets;
    }

    var canUseMoreTypeablePassword = _canUseMoreTypeablePasswordFromRequirements(minPasswordLength, maxPasswordLength, allowedCharacters, requiredCharacterSets);
    if (canUseMoreTypeablePassword) {
        var style =  PasswordGenerationStyle.MoreTypeable;
        if (allowedCharacters && (allowedCharacters.indexOf("-") === -1))
            style = PasswordGenerationStyle.MoreTypeableWithoutDashes;

        return { "PasswordGenerationStyle": style };
    }

    // If requirements allow, we will generate the password in default format: "xxx-xxx-xxx-xxx".
    var style = PasswordGenerationStyle.Classic;
    var numberOfRequiredRandomCharacters = defaultNumberOfCharactersForClassicPassword;
    if (minPasswordLength && minPasswordLength > defaultClassicPasswordLength) {
        style = PasswordGenerationStyle.ClassicWithoutDashes;
        numberOfRequiredRandomCharacters = minPasswordLength;
    }

    if (maxPasswordLength && maxPasswordLength < defaultClassicPasswordLength) {
        style = PasswordGenerationStyle.ClassicWithoutDashes;
        numberOfRequiredRandomCharacters = maxPasswordLength;
    }

    if (allowedCharacters) {
        // We cannot use default format if dash is not an allowed character in the password.
        if (allowedCharacters.indexOf("-") === -1)
            style = PasswordGenerationStyle.ClassicWithoutDashes;
    } else
        allowedCharacters = defaultUnambiguousCharacters;

    // In default password format, we use dashes only as separators, not as symbols you can encounter at a random position.
    if (style == PasswordGenerationStyle.Classic)
        allowedCharacters = allowedCharacters.replace(/-/g, "");

    if (!requiredCharacterSets)
        requiredCharacterSets = _defaultRequiredCharacterSets();

    // If we have more requirements of the type "need a character from set" than the length of the password we want to generate, then
    // we will never be able to meet these requirements, and we'll end up in an infinite loop generating passwords. To avoid this,
    // reset required character sets if the requirements are impossible to meet.
    if (requiredCharacterSets.length > numberOfRequiredRandomCharacters) {
        requiredCharacterSets = null;
    }

    // Do not require any character sets that do not contain allowed characters.
    var requiredCharacterSetsLength = requiredCharacterSets.length;
    var mutatedRequiredCharacterSets = [];
    var allowedCharactersLength = allowedCharacters.length;
    for (var i = 0; i < requiredCharacterSetsLength; i++) {
        var requiredCharacterSet = requiredCharacterSets[i];
        var requiredCharacterSetContainsAllowedCharacters = false;
        for (var j = 0; j < allowedCharactersLength; j++) {
            var character = allowedCharacters.charAt(j);
            if (requiredCharacterSet.indexOf(character) !== -1) {
                requiredCharacterSetContainsAllowedCharacters = true;
                break;
            }
        }
        if (requiredCharacterSetContainsAllowedCharacters)
            mutatedRequiredCharacterSets.push(requiredCharacterSet);
    }
    requiredCharacterSets = mutatedRequiredCharacterSets;

    return {
        "PasswordGenerationStyle": style,
        "NumberOfRequiredRandomCharacters": numberOfRequiredRandomCharacters,
        "PasswordAllowedCharacters": allowedCharacters,
        "RequiredCharacterSets": requiredCharacterSets,
    };
}

function generatedPasswordMatchingRequirements(requirements)
{
    requirements = requirements ? requirements : {};

    var parameters = _passwordGenerationParametersDictionary(requirements);
    var style = parameters["PasswordGenerationStyle"];
    var numberOfRequiredRandomCharacters = parameters["NumberOfRequiredRandomCharacters"];
    var repeatedCharLimit = requirements["PasswordRepeatedCharacterLimit"];
    var allowedCharacters = parameters["PasswordAllowedCharacters"];
    var shouldCheckRepeatedCharRequirement = repeatedCharLimit ? true : false;

    while (true) {
        var password;
        switch (style) {
            case PasswordGenerationStyle.Classic:
            case PasswordGenerationStyle.ClassicWithoutDashes:
                password = _classicPassword(numberOfRequiredRandomCharacters, allowedCharacters);
                if (style === PasswordGenerationStyle.Classic)
                    password = password.substr(0, 3) + "-" + password.substr(3, 3) + "-" + password.substr(6, 3) + "-" + password.substr(9, 3);

                if (!_passwordContainsRequiredCharacters(password, parameters["RequiredCharacterSets"]))
                    continue;

                break;
            case PasswordGenerationStyle.MoreTypeable:
            case PasswordGenerationStyle.MoreTypeableWithoutDashes:
                password = _moreTypeablePassword();
                if (style === PasswordGenerationStyle.MoreTypeable)
                    password = password.substr(0, 6) + "-" + password.substr(6, 6) + "-" + password.substr(12, 6);

                if (shouldCheckRepeatedCharRequirement && repeatedCharLimit !== 1)
                    shouldCheckRepeatedCharRequirement = false;

                break;
        }

        if (shouldCheckRepeatedCharRequirement) {
            if (repeatedCharLimit >= 1 && !_passwordHasNotExceededRepeatedCharLimit(password, repeatedCharLimit))
                continue;
        }

        var consecutiveCharLimit = requirements["PasswordConsecutiveCharacterLimit"]
        if (consecutiveCharLimit) {
            if (consecutiveCharLimit >= 1 && !_passwordHasNotExceededConsecutiveCharLimit(password, consecutiveCharLimit))
                continue;
        }

        return password;
    }
}