#
import sh
import os.path
import sys
import datetime

def printAnnotation(fp=sys.stdout):
    SDIR=os.path.dirname(os.path.realpath(sys.argv[0]))
    GITDIR="--git-dir=%s/.git" % (SDIR)
    WORKTREE="--work-tree=%s" % (SDIR)
    VERSIONBRANCH=sh.git(GITDIR,WORKTREE,"describe","--all").strip()
    VERSIONTAG=sh.git(GITDIR,WORKTREE,"describe","--long","--always").strip()
    try:
        REMOTE_ORIGIN_URL=sh.git(GITDIR,WORKTREE,"config","--get","remote.origin.url").strip()
    except:
        REMOTE_ORIGIN_URL=SDIR

    UNTRACKED=sh.git(GITDIR,WORKTREE,"status","--porcelain").strip()
    if UNTRACKED!="":
        UNTRACKED=" [UnCommitted Changes %s]" % (str(datetime.datetime.today()))

    print >>fp, "#CBE:%s (%s) (%s)%s" % (REMOTE_ORIGIN_URL,VERSIONBRANCH,VERSIONTAG,UNTRACKED)
    print >>fp, "#CBE:%s %s" % (os.path.realpath(sys.argv[0]),
                          " ".join(sys.argv[1:]))

if __name__=="__main__":
    printAnnotation()

