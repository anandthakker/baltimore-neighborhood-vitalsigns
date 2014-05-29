# From http://www.damian.oquanta.info/posts/one-line-deployment-of-your-site-to-gh-pages.html

# For initial setup of the gh-pages branch:
#
# git checkout -b gh-pages
# git rm -rf .
# git commit -am "First commit to gh-pages branch"
# git push origin gh-pages
#
# git checkout master # you can avoid this line if you are in master...
# git subtree split --prefix output -b gh-pages # create a local gh-pages branch containing the splitted output folder
# git push -f origin gh-pages:gh-pages # force the push of the gh-pages branch to the remote gh-pages branch at origin
# git branch -D gh-pages # delete the local gh-pages because you will need it: ref

git subtree push --prefix dist origin gh-pages
