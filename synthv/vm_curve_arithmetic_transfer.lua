local SCRIPT_TITLE = "Parameter Curve Arithmetic Transfer"
local DESCRIPTION = "Transfer parameter curves with arithmetic for parameter mixing."..
"\n\nVocal modes are entered as the name of the mode."..
"\nOther parameters are as follows:"..
"\nPitch Deviation = pitchDelta"..
"\nVibrato Envelope = vibratoEnv"..
"\nTone Shift = toneShift"..
"\nThe rest = all lowercase version of the name"..
"\n\nSupported operations:"..
"\n - basic arithmetic: +, -, *, /"..
"\n - exponentiation: ^"..
"\n - natural exponential function: exp(x)"..
"\n - natural and base 10 logarithm: ln(x), log(x)"..
"\n - positive part function: pos(x) = max(x, 0)"..
"\n - negative part function: neg(x) = -min(x, 0)"..
"\n - absolute value function: abs(x)";

function getClientInfo()
    return {
        name =  SV:T(SCRIPT_TITLE),
        author =  "UtaUtaUtau",
        category =  "Uta's Shenanigans",
        versionNumber =  2,
        minEditorVersion =  65537
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
    elseif type(o) == "string" then
        return '"'..o..'"'
    else
        return tostring(o)
    end
end

function dump(o) -- dump but with defaults
    return _dump(o, 4)
end

function count(str, pattern) -- count how many instances of pattern is in str
    return select(2, string.gsub(str, pattern, ""))
end

function inKeys(key, t) -- check if the key is in the keys of a table
    return t[key] ~= nil
end

local inputForm = {
    title = SV:T(SCRIPT_TITLE),
    message = SV:T(DESCRIPTION),
    buttons = "OkCancel",
    widgets = {
        {
            name = "expr", type = "TextBox",
            label = "Enter mathematical expression here",
            default = "0.5 * Powerful + 0.5 * Heavy"
        },
        {
            name = "dst", type =  "TextBox",
            label = "Enter the vocal mode to write to",
            default = "Power"
        },
        {
            name = "sampleEvenly", type = "CheckBox",
            text = "Sample automation evenly",
            default = false
        },
        {
            name = "divisions", type = "Slider",
            label = "Divisions per quarter if sampling evenly",
            format = "%.0f",
            minValue = 1, maxValue = 32,
            interval = 1,
            default = 16
        },
        {
            name = "asDecimal", type = "CheckBox",
            text = "Convert percentages to decimal for calculations",
            default = true
        },
        {
            name = "asSemitones", type = "CheckBox",
            text = "Use semitones for pitch deviation",
            default = true
        },
        {
            name = "asAmp", type = "CheckBox",
            text = "Convert dB to amplitude for loudness",
            default = true
        },
        {
            name = "clearDest", type = "CheckBox",
            text = "Clear target automation",
            default = true
        },
        {
            name = "clearSrc", type = "CheckBox",
            text = "Clear source automations",
            default = false
        },
        {
            name = "simplify", type = "CheckBox",
            text = "Simplify curve after transfer",
            default = false
        }
    }
}

-- INTERPRETER
local OPERATORS = {
    pos = "FPOS",
    neg = "FNEG",
    abs = "FABS",
    exp = "FEXP",
    ln = "FLN",
    log = "FLOG"
}
local PARAMS = {
    pitchDelta = true,
    vibratoEnv = true,
    loudness = true,
    tension = true,
    breathiness = true,
    voicing = true,
    gender = true
}
OPERATORS["+"] = "ADD"
OPERATORS["-"] = "SUB"
OPERATORS["*"] = "MUL"
OPERATORS["/"] = "DIV"
OPERATORS["^"] = "EXP"
OPERATORS["("] = "LPAR"
OPERATORS[")"] = "RPAR"
local DIGIT_PATTERN = "[%d%.]"
local PARAMETER_PATTERN = "[A-Za-z_]"

function tokenize(expr) -- turn string expression into tokens
    if count(expr, "[%(]") ~= count(expr, "[%)]") then return nil end -- skip if there are missing parentheses

    local tokens = {}
    local i = 1
    local length = expr:len()
    local prev = "#"
    while i <= length do -- tokenize
        local curr = expr:sub(i, i)
        local func = nil
        local ln = nil
        if i <= length - 2 then
            func = expr:sub(i, i+2):lower()
        end
        if i <= length - 1 then
            ln = expr:sub(i, i+1):lower()
        end
        if inKeys(curr, OPERATORS) then -- operator tokens
            if (inKeys(prev, OPERATORS) or i == 1) and curr == "-" then
                table.insert(tokens, {token="NEG"})
            else
                table.insert(tokens, {token=OPERATORS[curr]})
            end
        elseif inKeys(func, OPERATORS) then
            table.insert(tokens, {token=OPERATORS[func]})
            i = i + 2
        elseif inKeys(ln, OPERATORS) then
            table.insert(tokens, {token=OPERATORS[ln]})
            i = i + 1
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
    if tokenType == "NEG" or tokenType:match("^[F]") then
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
    if o.answers == nil then o.answers = {} end
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
            self.automations[node.value] = readParameter(noteGroup, node.value)
        end
        local value = self.automations[node.value]:get(blick)
        if self.answers.asDecimal and not PARAMS[node.value] then
            return 0.01 * value
        elseif self.answers.asSemitones and node.value == "pitchDelta" then
            return 0.01 * value
        elseif self.answers.asAmp and node.value == "loudness" then
            return math.pow(10.0, 0.05 * value)
        else
            return value
        end
    elseif node.op == "NEG" then
        return -self:evalNode(node.down, noteGroup, blick)
    elseif node.op == "FPOS" then
        return math.max(self:evalNode(node.down, noteGroup, blick), 0)
    elseif node.op == "FNEG" then
        return -math.min(self:evalNode(node.down, noteGroup, blick), 0)
    elseif node.op == "FABS" then
        return math.abs(self:evalNode(node.down, noteGroup, blick))
    elseif node.op == "FLOG" then
        return math.log10(self:evalNode(node.down, noteGroup, blick))
    elseif node.op == "FLN" then
        return math.log(self:evalNode(node.down, noteGroup, blick))
    elseif node.op == "FEXP" then
        return math.exp(self:evalNode(node.down, noteGroup, blick))
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

function Evaluator:eval(param, noteGroup, blick) -- Evaluate from root
    local result = self:evalNode(self.root, noteGroup, blick)
    if self.answers.asDecimal and not PARAMS[param] then
        return result * 100
    elseif self.answers.asSemitones and param == "pitchDelta" then
        return result * 100
    elseif self.answers.asAmp and node.value == "loudness" then
        return 20 * math.log10(result)
    else
        return result
    end
end

function readParameter(noteGroup, param) -- read parameter but in a slay way
    if PARAMS[param] then
        return noteGroup:getParameter(param)
    end
    return noteGroup:getParameter("vocalMode_"..param)
end

function messageBox(message) -- quick message box
    SV:showMessageBox(SCRIPT_TITLE, message)
end

function toboolean(str)
    if str == nil then return false end
    return str:lower() == "true"
end

function dumpConfig(file, answers)
    local f = io.open(file, "w")
    if f then
        f:write(dump(answers))
        f:close()
    end
end

function loadConfig(file)
    local f, err = io.open(file, "r")
    if f then
        local config = load("return "..f:read("*a"))()
        local widgets = {}
        for _, v in ipairs(inputForm.widgets) do
            widgets[v.name] = v
        end
        for k, v in pairs(config) do
            widgets[k].default = v
        end
    end
end

function main()
    local currNoteGroup = SV:getMainEditor():getCurrentGroup():getTarget() -- get current group
    local configFile = SV:getProject():getFileName():gsub("svp$", "PCAT.cfg")
    loadConfig(configFile)

    local result = SV:showCustomDialog(inputForm) -- show dialog

    if result.status then -- if success
        dumpConfig(configFile, result.answers)
        -- get target automation
        local dstAuto = readParameter(currNoteGroup, result.answers.dst)
        -- make temp automation and clear
        local tempAuto = dstAuto:clone()
        tempAuto:removeAll()
        
        -- read all source automations
        local automations = {}
        local evalBlicks = {}
        for auto in result.answers.expr:gmatch(PARAMETER_PATTERN.."+") do
            if not OPERATORS[auto] then
                local currAuto = readParameter(currNoteGroup, auto)
                automations[auto] = currAuto

                local points = currAuto:getAllPoints()
                if result.answers.sampleEvenly then
                    if #evalBlicks == 0 then evalBlicks = {math.huge, -math.huge} end
                    evalBlicks[1] = math.min(evalBlicks[1], points[1][1])
                    evalBlicks[2] = math.max(evalBlicks[2], points[#points][1])
                else
                    for _, point in ipairs(points) do
                        table.insert(evalBlicks, point[1])
                    end
                end
            end
        end
        if result.answers.sampleEvenly then
            local blicks = {evalBlicks[1]}
            while blicks[#blicks] <= evalBlicks[2] do
                table.insert(blicks, blicks[#blicks] + SV.QUARTER / result.answers.divisions)
            end
            evalBlicks = blicks
        else
            table.sort(evalBlicks)
        end

        -- interpret mathematical expression
        local tokens = tokenize(result.answers.expr)
        local parser = Parser:new{tokens=tokens}
        local ast = parser:parse()
        local expr = Evaluator:new{root=ast, automations=automations, answers=result.answers}

        -- calculate expression for all blicks required and add points to target automation
        for _, blick in ipairs(evalBlicks) do
            local value = expr:eval(result.answers.dst, currNoteGroup, blick)
            tempAuto:add(blick, value)
        end

        -- clear all source automations if enabled
        if result.answers.clearSrc then
            for _, auto in pairs(automations) do auto:removeAll() end
        end

        -- clear destination automation if enabled
        if result.answers.clearDest then dstAuto:removeAll() end

        -- transfer temp automation to destination automation
        for _, point in ipairs(tempAuto:getAllPoints()) do
            dstAuto:add(point[1], point[2])
        end

        -- simplify if enabled
        if result.answers.simplify then dstAuto:simplify(evalBlicks[1], evalBlicks[#evalBlicks]) end
    end
    SV:finish();
end