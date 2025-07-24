--Small easings lib with easing functions from easings.net
local c1 = 1.70158
local c2 = c1 * 1.525
local c3 = c1 + 1
local c4 = (2 * math.pi) / 3
local c5 = (2 * math.pi) / 4.5

function easeInSine(x)
    return 1 - math.cos((x * math.pi) / 2)
end

function easeOutSine(x)
    return math.sin((x * math.pi) / 2)
end

function easeInOutSine(x)
    return -(math.cos(math.pi * x) - 1) / 2
end

function easeInQuad(x)
    return x * x
end

function easeOutQuad(x)
    local xp = 1 - x
    return 1 - xp * xp
end

function easeInOutQuad(x)
    if x < 0.5 then
        return 2 * x * x
    else
        local t = -2 * x + 2
        return 1 - t * t / 2
    end
end

function easeInCubic(x)
    return x * x * x
end

function easeOutCubic(x)
    local xp = 1 - x
    return 1 - xp * xp * xp
end

function easeInOutCubic(x)
    if x < 0.5 then
        return 4 * x * x * x
    else
        local t = -2 * x + 2
        return 1 - t * t * t / 2
    end
end

function easeInQuart(x)
    return x * x * x * x
end

function easeOutQuart(x)
    local xp = 1 - x
    return 1 - xp * xp * xp * xp
end

function easeInOutQuart(x)
    if x < 0.5 then
        return 8 * x * x * x * x
    else
        local t = -2 * x + 2
        return 1 - t * t * t * t / 2
    end
end

function easeInQuint(x)
    return x * x * x * x * x
end

function easeOutQuint(x)
    local xp = 1 - x
    return 1 - xp * xp * xp * xp * xp
end

function easeInOutQuint(x)
    if x < 0.5 then
        return 16 * x * x * x * x * x
    else
        local t = -2 * x + 2
        return 1 - t * t * t * t * t / 2
    end
end

function easeInExpo(x)
    if x == 0 then return 0 end
    return math.pow(2, 10 * x - 10)
end

function easeOutExpo(x)
    if x == 1 then return 1 end
    return 1 - math.pow(2, -10 * x)
end

function easeInOutExpo(x)
    if x == 0 then return 0 end
    if x == 1 then return 1 end
    if x < 0.5 then
        return math.pow(2, 20 * x - 10) / 2
    else
        return (2 - math.pow(2, -20 * x + 10)) / 2
    end
end

function easeInCirc(x)
    return 1 - math.sqrt(1 - x * x)
end

function easeOutCirc(x)
    local t = x - 1
    return math.sqrt(1 - t * t)
end

function easeInOutCirc(x)
    if x < 0.5 then
        local t = 2 * x
        return (1 - math.sqrt(1 - t * t)) / 2
    else
        local t = -2 * x + 2
        return (math.sqrt(1 - t * t) + 1) / 2
    end
end

function easeInBack(x)
    return c3 * x * x * x - c1 * x * x
end

function easeOutBack(x)
    local t = x - 1
    return 1 + c3 * t * t * t + c1 * t * t
end

function easeInOutBack(x)
    if x < 0.5 then
        local t = 2 * x
        return (t * t * ((c2 + 1) * t - c2)) / 2
    else
        local t = 2 * x - 2
        return (t * t * ((c2 + 1) * t + c2) + 2) / 2
    end
end

function easeInElastic(x)
    if x == 0 then return 0 end
    if x == 1 then return 1 end
    return -math.pow(2, 10 * x - 10) * math.sin((x * 10 - 10.75) * c4)
end

function easeOutElastic(x)
    if x == 0 then return 0 end
    if x == 1 then return 1 end
    return math.pow(2, -10 * x) * math.sin((x * 10 - 10.75) * c4) + 1
end

function easeInOutElastic(x)
    if x == 0 then return 0 end
    if x == 1 then return 1 end
    if x < 0.5 then
        return -(math.pow(2, 20 * x - 10) * math.sin((20 * x - 11.125) * c5)) / 2
    else
        return (math.pow(2, -20 * x + 10) * math.sin((20 * x - 11.125) * c5)) / 2 + 1
    end
end

function easeOutBounce(x)
    local n1 = 7.5625
    local d1 = 2.75
    
    if x < 1 / d1 then
        return n1 * x * x
    elseif x < 2 / d1 then
        local t = x - 1.5 / d1
        return n1 * t * t + 0.75
    elseif x < 2.5 / d1 then
        local t = x - 2.25 / d1
        return n1 * t * t + 0.9375
    else
        local t = x - 2.625 / d1
        return n1 * t * t + 0.984375
    end
end

function easeInBounce(x)
    return 1 - easeOutBounce(1 - x)
end

function easeInOutBounce(x)
    if x < 0.5 then
        return (1 - easeOutBounce(1 - 2 * x)) / 2
    else
        return (1 + easeOutBounce(2 * x - 1)) / 2
    end
end

eases = {
    easeInSine,
    easeOutSine,
    easeInOutSine,
    easeInQuad,
    easeOutQuad,
    easeInOutQuad,
    easeInCubic,
    easeOutCubic,
    easeInOutCubic,
    easeInQuart,
    easeOutQuart,
    easeInOutQuart,
    easeInQuint,
    easeOutQuint,
    easeInOutQuint,
    easeInExpo,
    easeOutExpo,
    easeInOutExpo,
    easeInCirc,
    easeOutCirc,
    easeInOutCirc,
    easeInBack,
    easeOutBack,
    easeInOutBack,
    easeInElastic,
    easeOutElastic,
    easeInOutElastic,
    easeInBounce,
    easeOutBounce,
    easeInOutBounce
}