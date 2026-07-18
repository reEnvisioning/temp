.pragma library

function go(query, targets, opts) {
    opts = opts || {}
    var key = opts.key
    var limit = opts.limit || 15
    var threshold = opts.threshold !== undefined ? opts.threshold : -10000

    if (!query || !targets || targets.length === 0)
        return noResults

    var results = []
    for (var i = 0; i < targets.length; i++) {
        var target = key ? targets[i][key] : targets[i]
        if (typeof target !== "string") continue
        var score = scoreMatch(query, target)
        if (score !== null && score >= threshold)
            results.push({ obj: targets[i], score: score })
    }

    results.sort(function(a, b) { return b.score - a.score })
    if (limit > 0 && results.length > limit)
        results = results.slice(0, limit)
    results.total = results.length
    return results
}

function single(query, target) {
    var score = scoreMatch(query, target)
    if (score === null) return null
    return { obj: target, score: score }
}

function highlight(result, open, close) {
    if (!result || !result.obj) return ""
    return result.obj
}

function prepare(target) {
    return target
}

function scoreMatch(query, target) {
    if (!target) return null

    query = query.toLowerCase()
    target = target.toLowerCase()

    if (!query) return 0
    if (query.length > target.length) return null

    if (target.startsWith(query)) {
        var score = 1000 + query.length * 50
        if (target === query) score += 500
        return score
    }

    var score = 0
    var qi = 0
    var prev = -1

    for (var ti = 0; ti < target.length && qi < query.length; ti++) {
        if (target[ti] === query[qi]) {
            if (prev >= 0) {
                var gap = ti - prev - 1
                if (gap === 0) {
                    score += 15
                } else {
                    score -= gap
                    if (prev > 0 && (target[prev] === " " || target[prev] === "-" || target[prev] === "_"))
                        score += 5
                }
            } else {
                if (ti === 0) score += 10
                else if (target[ti - 1] === " " || target[ti - 1] === "-" || target[ti - 1] === "_") score += 8
                else score += 1
            }
            prev = ti
            qi++
        }
    }

    return qi === query.length ? score : null
}

var noResults = []
noResults.total = 0
