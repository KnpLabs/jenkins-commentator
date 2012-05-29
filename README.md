Configure the post-build hook and launch it on Heroku:

```
$ heroku create --stack cedar
$ heroku config:add NODE_ENV=production
$ heroku config:add GITHUB_USER_LOGIN=youruser
$ heroku config:add GITHUB_USER_PASSWORD=yourpassword
$ heroku config:add JENKINS_URL=http://yourjenkinsurl.com
$ git push heroku master
$ heroku ps:scale web=1
```

Then configure your Jenkins job to call the post-build hook to report
job status:

```
curl --data-urlencode out@${WORKSPACE}/report/progress.xml "http://yourapp.herokuapp.com/jenkins/post_build\
?user=yourusername\
&repo=yourreponame\
&sha=$GIT_COMMIT\
&status=$BUILD_STATUS\
&job=$BUILD_NUMBER"
```

With the Jenkins EnvInject Plugin, under Build > Inject environemnt variables > Properties Content, set `BUILD_STATUS` to `success` (this will only be set if the build succeeds):

	BUILD_STATUS=success
