dashing
=========

#### Running

Locally
```
bundle exec dashing start
```

Like Heroku
```
bundle exec thin start -R config.ru -e production -p 3030
```
Like Heroku with Procfile
```
bundle exec passenger start -p 3030 --spawn-method conservative
```

#### Deploy
```
git push heroku master
```
