# Setting up a new buildbot master

## Server database configuration

Buildbot can run without a database, but it takes about five extra
minutes to start up then.  So, create a real database for it to use.
For instance:
```
$ sudo apt install mysql-server
$ sudo mysql\_secure\_installation
$ mysql -u root -p
mysql> CREATE USER 'buildbot'@'localhost' IDENTIFIED BY 'my-db-password';
mysql> CREATE DATABASE buildhost5;
mysql> GRANT ALL PRIVILEGES ON buildhost5.\* TO 'buildbot'@'localhost';
mysql> quit;
```

Good luck with those passwords.  If you choose secure level 2 or higher,
better pick good ones, or login will fail.
I had to follow nasty recipes to reset the root sql password, e.g.
https://stackoverflow.com/questions/48861340/mysql-password-not-resetting-even-after-re-installation-on-ubuntu
(don't forget the mkdir and chown...)

## Master configuration

We require buildbot 1.21 or later, using python 3 (because python 2 is
just so much hurt once you get into virtualenv).

Installation should be simple.  At its heart, it's something like this:

```
$ mkdir -p ~/var/www
$ cp index.html ~/var/www
$ sudo apt install nginx
$ ... fiddle with nginx until ~/var/www/index.html is served properly ...
$ mkdir ~/master-state
$ cd ~/master-state
$ pip3 install --user \
   anybox.buildbot.capability \
   buildbot-console-view \
   buildbot-grid-view \
   buildbot-waterfall-view \
   buildbot-www \
   txrequests \
   #
$ which buildbot            # you may have to add $HOME/.local/bin to PATH
$ buildbot create-master --relocatable
$ cp ~/src/obs/buildbot/master.\* .
$ mkdir secrets.dir
$ chmod 700 secrets.dir
```

Before starting, follow instructions in master.cfg to populate
the one-line text files in secrets.dir, and make sure they're not
world-readable:

- my-buildbot-name
- my-buildbot-work-pw
- my-gitlab-appid
- my-gitlab-appsecret
- my-gitlab-token
- my-webhook-token
- my-db-url

Then start it:
```
$ buildbot start
```
and watch twistd.log to follow startup progress and look for errors.

Note that it will take a minute or two to start up; the big delays
are on the lines 'adding 1883 new builders' and 'adding 3766 new schedulers'.


## Gitlab configuration

When configuring a gitlab project to do try builds against this buildbot:
- add a webhook http://buildhost5.oblong.com:8010/change\_hook/gitlab for push, tag, and merge\_request events, with the secret from secrets.dir/my-webhook-token
- add the usual buildhost5 deploy key
- add user buildbot (or group share) with Developer or higher access to the project (and, when doing merge requests, to your fork of it)

## Worker configuration

On the workers, the procedure is roughly
```
$ mkdir slave-state
$ buildbot-worker create-worker --umask=0o22 slave-state buildhost5.oblong.com g-speak-$(hostname) $(cat .../my-buildbot-work-pw)
$ buildbot-worker start slave-state
```


