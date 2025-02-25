# local pipeline runner 

The purpose of this program is to locally emulate a pipeline job for convenient troubleshooting by
providing a local shell in which individual job commands/script lines can be executed individually and repeatedly.

## system configuration

* a docker daemon, Docker Desktop integrated with WSL, or otherwise some container runtime running on the local workstation
* networking + privileges to pull images from somewhere 
* a *nix shell, (cygwin on Windows) through which this program can be executed
* root or Administrator run-as privilege

If using cygwin, recommended to have the following helpful packages installed:

_these may not be strictly necessary for operation of the sandbox, however this is the package set installed on the initial Windows test host_ 

* cron
* kcron
* openssh
* rsync
* unzip
* vim
* zip

## file configuration 

### options/images.txt 

Full OCI paths for any images to be offered in the run menu

### options/users.txt 

In-container USER values to be offered in the run menu 

### options/platforms.txt 

Platform values to be offered in the run menu 

### env/gitlab_vars.env 

Group- or project-level environment variables expected as per gitlab's CI/CD settings

### pipeline-yaml/

Where any scripts go that will be emulating pipeline scripts.

This is up to you to create and maintain these files. Their contents are purely a convenience to you, the operator. When you 
find yourself in the running container, you will be in the OCI image of your choice, as the user of your choice, in the root 
of whatever repository you called this program. Any tools available therein are at your disposal. Files in pipeline-yaml can 
encapsulate any degree of complex operations you might want to run on a regular basis.

Future work for this program may include a script to scrape the .gitlab-ci.yml of the current repo and either transform those 
contents into scripts within pipeline-yaml or provide another method of executing an interpretation of the actual jobs by 
hand in the shell.

## installation 

something like 
```
sudo ln -sf $PWD/build-local.sh /usr/local/bin/runner
```

or on Windows, simply without the `sudo` in a cygwin shell "run as Administrator".

`/usr/local/bin` is typically in PATH by default, however technically any folder listed in `echo $PATH` for the user expected to run the sandbox will suffice.

## execution 

Calling 

```
runner -c COMMAND
```

will pass COMMAND as the container's COMMAND (default will be /bin/bash).
COMMAND will ultimately end up as an argument to `start.sh` (the ENTRYPOINT) and executed within the container.
All stdin/stderr will be captured in the running folder as start_TIMESTAMP.log.
