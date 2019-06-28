####  Git and GitHub   ####

It is a good idea to introduce yourself to Git with your name and public email address before doing any operation. The easiest
       way to do so is:

           $ git config --global user.name
           $ git config --global user.name "Your Name Comes Here"
           $ git config --global user.email you@yourdomain.example.com

#  Manual:
$ git --help tutorial

# To set GIT repository:

1) From the chosen directory:   $ git init

2) From the chosen directory:   $ git add  NomeFile

3) From the chosen directory:   $ git commit -m "Message"

4) From the chosen directory: 
$ git remote add origin git@github.com:username/reponame.git

5) From the chosen directory: 
$ git push origin master
***** if ReadMe file or gitignore or license have been already set in GitHub use
$ git push --mirror


***  to check the HEAD status:  
$ git status


####  Once everything has been set  #####
1)  Write code (modify files), then

$ git commit -m "Message"

2) $ git push origin master
  
