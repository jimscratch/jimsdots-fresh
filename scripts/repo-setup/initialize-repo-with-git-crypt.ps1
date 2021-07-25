# initialize the repository from git's template repo (~/.config/git/git-template) to ensure `main` set as default upstream remote branch
mkdir jimsdots-fresh && cd jimsdots-fresh && git init

# check status to ensure main is the branch checked out
git status

# add README.md, .gitignore, .gitattributes
touch README.md
touch .gitignore
touch .gitattributes

# initial git ignores
echo ".history/**" > .gitignore

# stage, commit and push
git add .
git commit -m "initialize repo with README.md, .gitignore, and .gitattributes"
git push

# initialize git-crypt with keyfile + GPG users
git-crypt init --keyfile ../gitcrypt-keyfile
git-crypt export-key ../gitcrypt-keyfile
git-crypt add-gpg-user jimmy.briggs@jimbrig.com
git-crypt add-gpg-user jimbrig1993@outlook.com


