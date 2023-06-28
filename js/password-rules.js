function userTypedRule() {
            return document.getElementById("passwordrule").value;
        }

        function minifiedPasswordRule(formatAsType) {
            let rule = userTypedRule();

            let min = minlengthAsNumber();
            if (min && !isNaN(min))
                rule = `minlength: ${min};` + rule;

            let max = maxlengthAsNumber();
            if (max && !isNaN(max))
                rule = `maxlength: ${max};` + rule;

            return minifiedBasePasswordRules(rule, formatAsType);
        }

        function minlengthAsNumber() {
            return parseInt(document.querySelector("#minlength").value);
        }

        function maxlengthAsNumber() {
            return parseInt(document.querySelector("#maxlength").value);
        }

        function validate(quirks, rule) {
            let ruleIsValid;
            if ((rule && rule.length > 0) || quirks) {
                document.querySelector("#passwordrule").classList.remove("invalid");
                ruleIsValid = true;
            } else {
                document.querySelector("#passwordrule").classList.add("invalid");
                ruleIsValid = false;
            }

            if (!quirks)
                quirks = {};
        
            let sampleGeneratedPasswordsConsole = document.getElementById("sampleGeneratedPasswordsConsole");
            if (ruleIsValid) {
                for (let buttonID of ["download100", "download1000", "download10000"])
                    document.getElementById(buttonID).removeAttribute("disabled");
        
                sampleGeneratedPasswordsConsole.innerText = stringWithNPasswordsSeparatedByNewlines(3, quirks);
            } else {
                for (let buttonID of ["download100", "download1000", "download10000"])
                    document.getElementById(buttonID).setAttribute("disabled", true);
        
                sampleGeneratedPasswordsConsole.innerText = "Invalid Rules\n\n";
            }
        
            updateCopyStrings();
        }

        function copyStringToClipboard(string) {
            function handler(event) {
                event.clipboardData.setData('text/plain', string);
                event.preventDefault();
                document.removeEventListener('copy', handler, true);
            }
        
            document.addEventListener('copy', handler, true);
            document.execCommand('copy');
        }
        
        function updateCopyStrings() {
            document.querySelector("#copyHTML").value = passwordRulesHTMLString();
            document.querySelector("#copyUIKit").value = passwordRulesUIKitString();
        }
        
        function passwordRulesHTMLString() {
            let pieces = []
        
            let minifiedRule = minifiedPasswordRule(FormatAs.HTML);
            if (minifiedRule)
                pieces.push(`passwordrules="${minifiedRule}"`);

            return pieces.join(" ");
        }
        
        function passwordRulesUIKitString() {
            let pieces = []
        
            let minifiedRule = minifiedPasswordRule(FormatAs.UIKit);
            if (minifiedRule)
                pieces.push(`${minifiedRule}`);

            return pieces.join(" ");
        }

        function copyWeb() {
            document.querySelector("#passwordrule").select();
            copyStringToClipboard(passwordRulesHTMLString());
            document.querySelector("#passwordrule").blur();
        }

        function stringWithNPasswordsSeparatedByNewlines(n, quirks) {
            let array = [];
            for (let i = 0; i < n; ++i)
                array.push(generatedPasswordMatchingRequirements(quirks));
        
            return array.join("\n");
        }

        function update() {
            let rule = minifiedPasswordRule(FormatAs.UIKit);
            let quirks = safariQuirkFromPasswordRules(rule);
            validate(quirks, rule);
        }

        function download(n) {
            let rule = minifiedPasswordRule(FormatAs.UIKit);
            let quirks = safariQuirkFromPasswordRules(rule);
        
            let blob = new Blob([stringWithNPasswordsSeparatedByNewlines(n, quirks)], {type: "plain/text"});
            let url = window.URL.createObjectURL(blob);
            let a = document.createElement("a");
            a.href = url;
            a.download = 'generated-passwords.txt';
            a.click();
        }
        
        function reset() {
            document.querySelector("#passwordrule").value =
`required: lower;
required: upper;
required: digit;
required: [-];`;
            document.querySelector("#minlength").value = "20";
            document.querySelector("#maxlength").value = "";
            update();
        }

        document.addEventListener("DOMContentLoaded", function(event) {
            reset();

            let textareas = document.getElementsByTagName('textarea');
            for (let i = 0; i < textareas.length; i++) {
                textareas[i].setAttribute('style', 'height:' + (textareas[i].scrollHeight) + 'px; overflow-y:hidden;');
                textareas[i].addEventListener("input", oninput, false);
            }
        
            function oninput() {
                this.style.height = 'auto';
                this.style.height = Math.max(this.scrollHeight, 40) + 'px';
            }
        
            let elements = document.querySelectorAll("textarea, input");
            for (let element of elements)
                element.addEventListener("input", update, false);
        
            update();
        });