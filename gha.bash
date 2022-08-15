#!/bin/bash

newCommit () {
  eval "git add ."

  read -p "type (ammend[A], fixup[F], drop[D], neither[ENTER])?: " commitType
  commitType=$(tr '[:upper:]' '[:lower:]'<<<${commitType})

  commitMessage=""
  if [ $commitType != "a" ];
  then
    read -p "commit message: " commitMessage || exit 1
  fi

  commitAction="-m '$commitMessage'"
  if [ ! -z "$commitType" ];
  then
    case $commitType in
      f | fixup)
        commitAction="-m 'fixup! $commitMessage'"
        ;;
      d | drop)
        commitAction="-m 'drop! $commitMessage'"
        ;;
      a | amend)
        commitAction='--amend'
        ;;
      *)
        exit 1
        ;;
    esac
  fi

  eval "git commit $commitAction"
  eval "git push --force-with-lease" 
  eval "gh pr view --web"
}

newPR () {
  branch=$(eval "git rev-parse --symbolic-full-name --abbrev-ref HEAD")

  if grep -q "master" <<< "$branch"; then
    read -p "new branch: " newBranch || exit 1
    eval "git checkout -b $newBranch"
    branch=$(eval "git rev-parse --symbolic-full-name --abbrev-ref HEAD")
  else
    read -p "branch (${branch}?): " newBranch
    [[ ! -z "$newBranch" ]] && branch=${newBranch}
  fi

  issue=(${branch//-/ }[0])

  currentIssueTitle=$(eval "gh issue view https://github.com/peckadesign/$repo/issues/$issue --json title")
  currentIssueTitle=$(eval "node -pe 'JSON.parse(process.argv[1]).title' '$currentIssueTitle'")
  currentIssueTitle=$(echo "$currentIssueTitle" | cut -d "-" -f 2)

  if [ $? -ne 0 ]; then
    currentIssueTitle=$(echo "$currentIssueTitle" | cut -d ":" -f 2)
  fi

  read -p "commit message ('$currentIssueTitle'?): " commit
  [[ -z "$commit" ]] && commit=${currentIssueTitle}

  eval "cd ~/repos/$repo/"
  eval "git add ."

  pr_title="#$issue $commit"

  if [ $repo = "contenteditor" ]; then
    read -p "type (feat, fix)?: " commitType || exit 1
    read -p "title?: " commitTitle || exit 1

    eval "git commit -m '$commitType($commitTitle): #$issue $commit'"
    pr_title="$commitType($commitTitle): #$issue $commit"
  else
    eval "git commit -m '#$issue $commit'"
  fi  

  eval "git push --set-upstream origin $branch"

  read -p "PR comment: " pr_comment
  pr_body="PR k #$issue<br /><br />$pr_comment"

  pr_url=$(eval "gh pr create --title '$pr_title' --body '$pr_body'")
  eval "open $pr_url"

  exit 1

  # pr=$(eval "node -pe \"'$prurl'.split('/').reverse()[0]\"")

  # issue_comment=`
  # - @petrzdansky @Filip743 @sebastianvass hotovo
  # - PR projektu https://github.com/peckadesign/nayeshop/pull/$pr
  # - K testovaní na
  #    - http://test$pr.nay2020.peckadesign.com`

  # read -p "comment? Y/n " comment
  # if [[ $comment == "n" || $comment == "N" ]]; then
  #   exit 1
  # fi

  # open -t /tmp/issue_comment.tmp
  # issue_comment=`cat /tmp/issue_comment.tmp`

  # comment_url=$(eval "gh issue comment https://github.com/peckadesign/$4/issues/$3 --body '${issue_comment}'")
  # eval "open $comment_url"
}

rebase () {
  eval "git fetch origin"
  eval "git rebase origin/master -i"
  eval "git push --force-with-lease"
}

while getopts a:r: flag
do
    case "${flag}" in
        a) action=${OPTARG};;
        r) repo=${OPTARG};;
    esac
done

if [ -z "$repo" ];
then
  read -p "repo (tool[T], eshop[E], content-editor[C], benu[B])?: " repo || exit 1
fi

action=$(tr '[:upper:]' '[:lower:]'<<<${action})
repo=$(tr '[:upper:]' '[:lower:]'<<<${repo})

case $repo in
  t | tool)
    repo='naytool'
    ;;
  e | eshop)
    repo='nayeshop'
    ;;
  c | content-editor)
    repo='contenteditor'
    ;;
  b | benu)
    repo='benu-frontend'
    ;;
  *)
    exit 1
    ;;
esac

eval "cd ~/repos/$repo/"

case $action in
  c | commit)
    newCommit
    ;;
  p | pr)
    newPR
    ;;
  r | rebase)
    rebase
    ;;
  rm | rebase-merge)
    rebase
    eval "gh pr merge --auto"
    ;;
  *)
    exit 1
    ;;
esac

exit 1

