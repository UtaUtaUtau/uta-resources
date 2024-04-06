local SCRIPT_TITLE = "Vocal Mode Curve Arithmetic Transfer"
local DESCRIPTION = "Transfer vocal mode parameters with arithmetic for parameter mixing.\nVocal modes are entered as the name of the mode."..
"\n\nSupported operations = "..
"\n - addition [+]"..
"\n - subtraction/negation [-]"..
"\n - multiplication [*]"..
"\n - division [/]"..
"\n - exponentiation [^]"..
"\n - parenthesis ()";

function getClientInfo()
    return {
        name =  SV:T(SCRIPT_TITLE),
        author =  "UtaUtaUtau",
        category =  "Uta's Shenanigans",
        versionNumber =  1,
        minEditorVersion =  0
    }
end

function _dump(o, indent) -- Debug print anything
    if type(o) == "table" then
        local str = "{"
        for k, v in pairs(o) do
            str = str.."\n"..string.rep(" ", indent)..k.." = ".._dump(v, indent+4)..","
        end
        str = str:sub(0, -2).."\n"..string.rep(" ", indent-4).."}"
        return str
    else
        return tostring(o)
    end
end

function dump(o) -- dumb but with defaults
    return _dump(o, 4)
end

function count(str, pattern) -- count how many instances of pattern is in str
    return select(2, string.gsub(str, pattern, ""))
end

function inKeys(key, t) -- check if the key is in the keys of a table
    for k, _ in pairs(t) do
        if key == k then return true end
    end
    return false
end

local inputForm = {
    title =  SV:T(SCRIPT_TITLE),
    message =  SV:T(DESCRIPTION),
    buttons =  "OkCancel",
    widgets =  {
        {
            name =  "expr", type =  "TextBox",
            label =  "Enter mathematical expression here",
            default =  "0.5 * Powerful + 0.5 * Heavy"
        },
        {
            name =  "dst", type =  "TextBox",
            label =  "Enter the vocal mode to write to",
            default =  "Power"
        },
        {
            name = "asDecimal", type = "CheckBox",
            text = "Convert percentages to decimal for calculations",
            default = true
        },
        {
            name = "clearDest", type = "CheckBox",
            text = "Clear target automation",
            default = true
        },
        {
            name =  "clearSrc", type =  "CheckBox",
            text =  "Clear source automations",
            default =  false
        },
        {
            name = "simplify", type =  "CheckBox",
            text = "Simplify curve after transfer",
            default =  false
        }
    }
}

local OPERATORS = {}
OPERATORS["+"] = "ADD"
OPERATORS["-"] = "SUB"
OPERATORS["*"] = "MUL"
OPERATORS["/"] = "DIV"
OPERATORS["^"] = "EXP"
OPERATORS["("] = "LPAR"
OPERATORS[")"] = "RPAR"
local DIGIT_PATTERN = "[%d%.]"
local OPERATOR_PATTERN = "[%+%-%*%/%^%(%)]"
local PARAMETER_PATTERN = "[A-Za-z_]"

function tokenize(expr) -- turn string expression into tokens
    if count(expr, "[%(]") ~= count(expr, "[%)]") then return nil end -- skip if there are missing parentheses

    local tokens = {}
    local i = 1
    local length = expr:len()
    local prev = "#"
    while i <= length do -- tokenize
        local curr = expr:sub(i, i)
        if curr:match(OPERATOR_PATTERN) then -- operator tokens
            if (prev:match(OPERATOR_PATTERN) or i == 1) and curr == "-" then
                table.insert(tokens, {token="NEG"})
            else
                table.insert(tokens, {token=OPERATORS[curr]})
            end
        elseif curr:match(DIGIT_PATTERN) then -- number tokens
            while (i + 1 <= length) and expr:sub(i + 1, i + 1):match(DIGIT_PATTERN) do
                i = i + 1
                curr = curr..expr:sub(i, i)
            end
            if curr:sub(1, 1) == "." then
                curr = "0"..curr
            end
            if curr:sub(-1, -1) == "." then
                curr = curr..0
            end
            table.insert(tokens, {token="NUM", value=tonumber(curr)})
        elseif curr:match(PARAMETER_PATTERN) then -- parameter tokens
            while (i + 1 <= length) and expr:sub(i + 1, i + 1):match(PARAMETER_PATTERN) do
                i = i + 1
                curr = curr..expr:sub(i, i)
            end
            table.insert(tokens, {token="PARAM", value=curr})
        end
        i = i + 1
        prev = curr
    end
    return tokens
end

-- Token parser
local Parser = {}

function Parser:new(o)
    o = o or {}
    o.length = #o.tokens
    o.i = 1
    setmetatable(o, self)
    self.__index = self
    return o
end

function Parser:parse() -- reverse PEMDAS, so add/sub first
    return self:addSub()
end

function Parser:addSub() -- setup all add/sub nodes
    local node = self:mulDiv()

    while self.i <= self.length and self.tokens[self.i].token:match("^[AS]") do
        local token = self.tokens[self.i].token
        if token == "ADD" then
            self.i = self.i + 1
            node = {op="ADD", left=node, right=self:mulDiv()}
        elseif token == "SUB" then
            self.i = self.i + 1
            node = {op="SUB", left=node, right=self:mulDiv()}
        end
    end
    return node
end

function Parser:mulDiv() -- setup all mul/div nodes
    local node = self:exp()

    while self.i <= self.length and self.tokens[self.i].token:match("^[MD]") do
        local token = self.tokens[self.i].token
        if token == "MUL" then
            self.i = self.i + 1
            node = {op="MUL", left=node, right=self:exp()}
        elseif token == "DIV" then
            self.i = self.i + 1
            node = {op="DIV", left=node, right=self:exp()}
        end
    end
    return node
end

function Parser:exp() -- setup all exp nodes
    local node = self:factor()

    while self.i <= self.length and self.tokens[self.i].token == "EXP" do
        self.i = self.i + 1
        node = {op="EXP", left=node, right=self:factor()}
    end
    return node
end

function Parser:factor() -- setup all nodes with down/value
    local tokenType = self.tokens[self.i].token
    local tokenValue = self.tokens[self.i].value
    if tokenType == "NEG" then
        self.i = self.i + 1
        return {op=tokenType, down=self:factor()}
    elseif tokenType == "LPAR" then
        self.i = self.i + 1
        local node = self:parse()
        if self.i <= self.length and self.tokens[self.i].token == "RPAR" then
            self.i = self.i + 1
            return node
        end
    elseif tokenType == "PARAM" then
        self.i = self.i + 1
        return {op=tokenType, value=tokenValue}
    elseif tokenType == "NUM" then
        self.i = self.i + 1
        return {op=tokenType, value=tokenValue}
    end
end

--Evaluate abstract syntax tree
local Evaluator = {}

function Evaluator:new(o)
    o = o or {}
    if o.automations == nil then o.automations = {} end
    if o.asDecimal == nil then o.asDecimal = true end
    setmetatable(o, self)
    self.__index = self
    return o
end

function Evaluator:evalNode(node, noteGroup, blick) -- Evaluate a node
    if node == nil then return nil end

    if node.op == "NUM" then
        return node.value
    elseif node.op == "PARAM" then
        if not inKeys(node.value, self.automations) then
            self.automations[node.value] = noteGroup:getParameter("vocalMode_"..node.value)
        end
        local value = self.automations[node.value]:get(blick)
        if self.asDecimal then
            return 0.01 * value
        else
            return value
        end
    elseif node.op == "NEG" then
        return -1 * self:evalNode(node.down, noteGroup, blick)
    elseif node.op == "EXP" then
        return math.pow(self:evalNode(node.left, noteGroup, blick), self:evalNode(node.right, noteGroup, blick))
    elseif node.op == "MUL" then
        return self:evalNode(node.left, noteGroup, blick) * self:evalNode(node.right, noteGroup, blick)
    elseif node.op == "DIV" then
        return self:evalNode(node.left, noteGroup, blick) / self:evalNode(node.right, noteGroup, blick)
    elseif node.op == "ADD" then
        return self:evalNode(node.left, noteGroup, blick) + self:evalNode(node.right, noteGroup, blick)
    elseif node.op == "SUB" then
        return self:evalNode(node.left, noteGroup, blick) - self:evalNode(node.right, noteGroup, blick)
    end
end

function Evaluator:eval(noteGroup, blick) -- Evaluate from root
    local result = self:evalNode(self.root, noteGroup, blick)
    if self.asDecimal then
        return result * 100
    else
        return result
    end
end

function debugMessage(message)
    SV:showMessageBox(SCRIPT_TITLE, message)
end

function main()
    local currNoteGroup = SV:getMainEditor():getCurrentGroup():getTarget() -- get current group
    local result = SV:showCustomDialog(inputForm) -- show dialog

    if result.status then -- if success
        -- get target automation and clear if enabled
        local dstAuto = currNoteGroup:getParameter("vocalMode_"..result.answers.dst)
        if result.answers.clearDest then dstAuto:removeAll() end
        
        -- read all source automations
        local automations = {}
        local evalBlicks = {}
        for auto in result.answers.expr:gmatch(PARAMETER_PATTERN.."+") do
            local currAuto = currNoteGroup:getParameter("vocalMode_"..auto)
            automations[auto] = curr_auto

            for _, point in ipairs(currAuto:getAllPoints()) do
                table.insert(evalBlicks, point[1])
            end
        end
        table.sort(evalBlicks)

        -- interpret mathematical expression
        local tokens = tokenize(result.answers.expr)
        local parser = Parser:new{tokens=tokens}
        local ast = parser:parse()
        local expr = Evaluator:new{root=ast, automations=automations, asDecimal=result.answers.asDecimal}

        -- calculate expression for all blicks required and add points to target automation
        for _, blick in ipairs(evalBlicks) do
            local value = expr:eval(currNoteGroup, blick)
            dstAuto:add(blick, value)
        end

        -- clear all source automations if enabled
        if result.answers.clearSrc then
            for _, auto in pairs(automations) do auto:removeAll() end
        end

        -- simplify if enabled
        if result.answers.simplify then dstAuto:simplify(evalBlicks[1], evalBlicks[#evalBlicks]) end
    end
    SV:finish();
end