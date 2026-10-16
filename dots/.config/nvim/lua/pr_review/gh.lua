-- GitHub side of pr_review: one load of a PR's review state (GraphQL, paged)
-- and the mutations behind the review actions. Everything goes through the gh
-- CLI, so auth is whatever `gh auth` has. Callbacks run on the main loop.
local M = {}

---@param args string[]
---@param input? string
---@param cb fun(err?: string, out?: string)
function M.run(args, input, cb)
    vim.system(vim.list_extend({ "gh" }, args), { stdin = input, text = true }, function(obj)
        vim.schedule(function()
            if obj.code ~= 0 then
                cb(vim.trim(obj.stderr ~= "" and obj.stderr or obj.stdout))
            else
                cb(nil, obj.stdout)
            end
        end)
    end)
end

local function decode(out)
    if not out or not out:find("%S") then
        return nil
    end
    local ok, data = pcall(vim.json.decode, out, { luanil = { object = true, array = true } })
    return ok and data or nil
end

-- `gh api <endpoint>` with a JSON body
---@param cb fun(err?: string, data?: table)
function M.api(endpoint, body, cb, method)
    M.run({ "api", endpoint, "--method", method or "POST", "--input", "-" }, vim.json.encode(body), function(err, out)
        cb(err, not err and decode(out) or nil)
    end)
end

---@param cb fun(err?: string, data?: table)
function M.graphql(query, variables, cb)
    M.api("graphql", { query = query, variables = variables }, function(err, data)
        if err then
            return cb(err)
        end
        if data and data.errors then
            local msgs = vim.tbl_map(function(e)
                return e.message
            end, data.errors)
            return cb(table.concat(msgs, "\n"))
        end
        cb(nil, data and data.data)
    end)
end

local PR_QUERY = [[
query($owner: String!, $name: String!, $number: Int!) {
  viewer { login }
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      id number title url state isDraft
      author { login }
      headRefName headRefOid baseRefName isCrossRepository
      headRepositoryOwner { login }
      baseRepository { nameWithOwner }
      reviewDecision
      reviews(states: PENDING, first: 1) { nodes { id } }
      commits(last: 1) { nodes { commit { statusCheckRollup { state } } } }
    }
  }
}]]

local THREADS_QUERY = [[
query($owner: String!, $name: String!, $number: Int!, $cursor: String) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      page: reviewThreads(first: 50, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id path line startLine originalLine originalStartLine diffSide startDiffSide
          isResolved isOutdated subjectType viewerCanReply viewerCanResolve viewerCanUnresolve
          resolvedBy { login }
          comments(first: 100) {
            nodes {
              id databaseId body createdAt url state
              viewerDidAuthor viewerCanUpdate viewerCanDelete viewerCanReact
              author { login } authorAssociation
              reactionGroups { content viewerHasReacted reactors { totalCount } }
            }
          }
        }
      }
    }
  }
}]]

local FILES_QUERY = [[
query($owner: String!, $name: String!, $number: Int!, $cursor: String) {
  repository(owner: $owner, name: $name) {
    pullRequest(number: $number) {
      page: files(first: 100, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        nodes { path additions deletions viewerViewedState }
      }
    }
  }
}]]

local function split_repo(repo)
    local owner, name = repo:match("^([^/]+)/([^/]+)$")
    return { owner = owner, name = name }
end

-- all pages of a PR connection aliased `page`
local function paged(query, repo, number, cb)
    local nodes = {}
    local function next_page(cursor)
        local vars = split_repo(repo)
        vars.number, vars.cursor = number, cursor
        M.graphql(query, vars, function(err, data)
            local page = data and vim.tbl_get(data, "repository", "pullRequest", "page")
            if err or not page then
                return cb(err or "no pull request data")
            end
            vim.list_extend(nodes, page.nodes or {})
            if page.pageInfo.hasNextPage then
                return next_page(page.pageInfo.endCursor)
            end
            cb(nil, nodes)
        end)
    end
    next_page(nil)
end

-- iso8601 UTC -> epoch
local function epoch(s)
    local y, mo, d, h, mi, sec = (s or ""):match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
    if not y then
        return os.time()
    end
    local t = os.time({ year = y, month = mo, day = d, hour = h, min = mi, sec = sec, isdst = false })
    local now = os.time()
    local utc = os.date("!*t", now) --[[@as osdate]]
    utc.isdst = false
    return t + os.difftime(now, os.time(utc))
end

local function normalize_thread(t)
    t.diffSide = t.diffSide or "RIGHT"
    t.comments = t.comments and t.comments.nodes or {}
    for _, c in ipairs(t.comments) do
        c.created = epoch(c.createdAt)
        c.author = c.author or { login = "ghost" }
        c.reactions = {}
        for _, g in ipairs(c.reactionGroups or {}) do
            local count = g.reactors and g.reactors.totalCount or 0
            if count > 0 then
                c.reactions[#c.reactions + 1] = { content = g.content, count = count, mine = g.viewerHasReacted }
            end
        end
        c.reactionGroups = nil
    end
    -- a pending thread only exists in the viewer's pending review
    t.pending = #t.comments > 0 and vim.iter(t.comments):all(function(c)
        return c.state == "PENDING"
    end)
    return t
end

---@class pr_review.Data
---@field viewer string
---@field pr table
---@field pending? string pending review node id
---@field threads table[]
---@field files table<string, {additions: integer, deletions: integer, viewed: boolean}>

-- Fetch PR metadata only (worktree setup needs it before the threads).
---@param cb fun(err?: string, viewer?: string, pr?: table)
function M.pr(repo, number, cb)
    local vars = split_repo(repo)
    vars.number = number
    M.graphql(PR_QUERY, vars, function(err, data)
        local pr = data and vim.tbl_get(data, "repository", "pullRequest")
        if err or not pr then
            return cb(err or ("PR %s#%d not found"):format(repo, number))
        end
        cb(nil, data.viewer.login, pr)
    end)
end

---@param cb fun(err?: string, data?: pr_review.Data)
function M.load(repo, number, cb)
    local ret = { files = {} } ---@type pr_review.Data
    local todo, failed = 3, nil
    local function done(err)
        failed = failed or err
        todo = todo - 1
        if todo == 0 then
            cb(failed, not failed and ret or nil)
        end
    end
    M.pr(repo, number, function(err, viewer, pr)
        if pr then
            ret.viewer, ret.pr = viewer, pr
            local pending = vim.tbl_get(pr, "reviews", "nodes", 1)
            ret.pending = pending and pending.id
        end
        done(err)
    end)
    paged(THREADS_QUERY, repo, number, function(err, nodes)
        ret.threads = vim.tbl_map(normalize_thread, nodes or {})
        done(err)
    end)
    paged(FILES_QUERY, repo, number, function(err, nodes)
        for _, f in ipairs(nodes or {}) do
            ret.files[f.path] =
                { additions = f.additions, deletions = f.deletions, viewed = f.viewerViewedState == "VIEWED" }
        end
        done(err)
    end)
end

-- Mutations take a single `input` object, named by their GraphQL input type.
local MUTATIONS = {
    add_thread = { "AddPullRequestReviewThreadInput", "addPullRequestReviewThread" },
    add_reply = { "AddPullRequestReviewThreadReplyInput", "addPullRequestReviewThreadReply" },
    add_review = { "AddPullRequestReviewInput", "addPullRequestReview", "pullRequestReview { id }" },
    submit_review = { "SubmitPullRequestReviewInput", "submitPullRequestReview" },
    delete_review = { "DeletePullRequestReviewInput", "deletePullRequestReview" },
    resolve = { "ResolveReviewThreadInput", "resolveReviewThread" },
    unresolve = { "UnresolveReviewThreadInput", "unresolveReviewThread" },
    add_reaction = { "AddReactionInput", "addReaction" },
    remove_reaction = { "RemoveReactionInput", "removeReaction" },
    edit_comment = { "UpdatePullRequestReviewCommentInput", "updatePullRequestReviewComment" },
    delete_comment = { "DeletePullRequestReviewCommentInput", "deletePullRequestReviewComment" },
    mark_viewed = { "MarkFileAsViewedInput", "markFileAsViewed" },
    unmark_viewed = { "UnmarkFileAsViewedInput", "unmarkFileAsViewed" },
}

---@param name string key of MUTATIONS
---@param cb fun(err?: string, result?: table)
function M.mutate(name, input, cb)
    local m = assert(MUTATIONS[name], name)
    local query = ("mutation($input: %s!) { result: %s(input: $input) { clientMutationId %s } }"):format(
        m[1],
        m[2],
        m[3] or ""
    )
    M.graphql(query, { input = input }, function(err, data)
        cb(err, data and data.result)
    end)
end

-- Comments posted right away, outside any review. GraphQL only knows review
-- threads, so these use the REST endpoints (as GitHub's "Add single comment").
---@param cb fun(err?: string)
function M.single_comment(repo, number, comment, cb)
    M.api(("repos/%s/pulls/%d/comments"):format(repo, number), comment, cb)
end

---@param cb fun(err?: string)
function M.single_reply(repo, number, comment_id, body, cb)
    M.api(("repos/%s/pulls/%d/comments/%d/replies"):format(repo, number, comment_id), { body = body }, cb)
end

return M
