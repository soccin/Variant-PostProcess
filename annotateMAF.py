import sh
import os.path
import sys

def printAnnotation(fp=sys.stdout):
    SDIR=os.path.dirname(os.path.realpath(sys.argv[0]))
    GITDIR="--git-dir=%s/.git" % (SDIR)
    WORKTREE="--work-tree=%s" % (SDIR)
    VERSIONBRANCH=sh.git(GITDIR,WORKTREE,"describe","--all").strip()
    VERSIONTAG=sh.git(GITDIR,WORKTREE,"describe","--long","--always").strip()
    REMOTE_ORIGIN_URL=sh.git(GITDIR,WORKTREE,"config","--get","remote.origin.url").strip()


    print >>fp, "#CBE:%s (%s) (%s)" % (REMOTE_ORIGIN_URL,VERSIONBRANCH,VERSIONTAG)
    print >>fp, "#CBE:%s %s" % (os.path.realpath(sys.argv[0]),
                          " ".join(sys.argv[1:]))

