dashing
=========

#### Running

Locally
```
dashing start
```

Like Heroku
```
bundle exec thin start -R config.ru -e production -p <port>
```
Like Heroku with Procfile
```
bundle exec passenger start -p <port> --spawn-method conservative
```

#### Deploy
```
git push heroku master
```
