# Usage:

async   = require 'async'
request = require 'request'
express = require 'express'
_       = require 'underscore'
_s      = require 'underscore.string'

PullRequestCommenter = require('./PullRequestCommenter.coffee').PullRequestCommenter

app = module.exports = express.createServer()
app.use(express.bodyParser());

app.configure 'development', ->
  app.set "port", 3000

app.configure 'production', ->
  app.use express.errorHandler()
  app.set "port", parseInt process.env.PORT

# Jenkins lets us know when a build has failed or succeeded.
app.post '/jenkins/post_build', (req, res) ->
  sha = req.param 'sha'
  job = parseInt req.param 'job'
  user = req.param 'user'
  repo = req.param 'repo'
  # out is the output of our test suite
  out = req.param 'out'
  succeeded = req.param('status') is 'success'

  # Look for an open pull request with this SHA and make comments.
  commenter = new PullRequestCommenter sha, job, user, repo, succeeded, out
  commenter.updateComments (e, r) -> console.log e if e?
  res.send 'Ok', 200

app.listen app.settings.port
