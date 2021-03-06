async   = require 'async'
request = require 'request'
_       = require 'underscore'
_s      = require 'underscore.string'

class exports.PullRequestCommenter
  BUILDREPORT = "**Build Status**:"

  constructor: (@sha, @job, @user, @repo, @succeeded, @out) ->
    @job_url = "#{process.env.JENKINS_URL}/job/Ideo/#{@job}"
    @api = "https://#{process.env.GITHUB_USER_LOGIN}:#{process.env.GITHUB_USER_PASSWORD}@api.github.com"

  post: (path, obj, cb) =>
    request.post { uri: "#{@api}#{path}", json: obj }, (e, r, body) ->
      cb e, body

  patch: (path, obj, cb) =>
    request.post { uri: "#{@api}#{path}", json: obj }, (e, r, body) ->
      cb e, body

  get: (path, cb) =>
    console.log "#{@api}#{path}"
    request.get { uri: "#{@api}#{path}", json: true }, (e, r, body) ->
      cb e, body

  del: (path, cb) =>
    request.del { uri: "#{@api}#{path}" }, (e, r, body) ->
      cb e, body

  getCommentsForIssue: (issue, cb) =>
    @get "/repos/#{@user}/#{@repo}/issues/#{issue}/comments", cb

  deleteComment: (id, cb) =>
    @del "/repos/#{@user}/#{@repo}/issues/comments/#{id}", cb

  getPulls: (cb) =>
    @get "/repos/#{@user}/#{@repo}/pulls", cb

  getPull: (id, cb) =>
    @get "/repos/#{@user}/#{@repo}/pulls/#{id}", cb

  setPullTitle: (issue, title) =>
    @patch "/repos/#{@user}/#{@repo}/pulls/#{issue}", ('title': title), (e, body) ->
      console.log e if e?

  commentOnIssue: (issue, comment) =>
    console.log "Commenting on issue #{issue}"
    @post "/repos/#{@user}/#{@repo}/issues/#{issue}/comments", (body: comment), (e, body) ->
      console.log e if e?

  successComment: ->
    "#{BUILDREPORT} [Success](#{@job_url})\n```\n#{@out}```"

  errorComment: ->
    "#{BUILDREPORT} [Failure](#{@job_url})\n```\n#{@out}```"

  # Find the first open pull with a matching HEAD sha
  findMatchingPull: (pulls, cb) =>
    pulls = _.filter pulls, (p) => p.state is 'open'
    async.detect pulls, (pull, detect_if) =>
      @getPull pull.number, (e, { head }) =>
        console.log head.sha
        return cb e if e?
        detect_if head.sha is @sha
    , (match) =>
      return cb "No pull request for #{@sha} found" unless match?
      cb null, match

  removePreviousPullComments: (pull, cb) =>
    @getCommentsForIssue pull.number, (e, comments) =>
      return cb e if e?
      old_comments = _.filter comments, ({ body }) -> _s.include body, BUILDREPORT
      async.forEach old_comments, (comment, done_delete) =>
        @deleteComment comment.id, done_delete
      , () -> cb null, pull

  makePullComment: (pull, cb) =>
    comment = if @succeeded then @successComment() else @errorComment()
    @commentOnIssue pull.number, comment
    return cb pull

  updatePullTitle: (pull, cb) =>
    prefix = if @succeeded then '[Tests pass] ' else '[Tests fail] '
    if pull.title.match /\[Tests (fail|pass)\] /
      title = pull.title.replace(/\[Tests (fail|pass)\] /, prefix)
    else
      title = prefix + pull.title
    console.log(title)
    @setPullTitle pull.number, title
    return cb()

  updateComments: (cb) ->
    async.waterfall [
      @getPulls
      @findMatchingPull
      @makePullComment
      @updatePullTitle
    ], cb
