{
  config,
  pkgs,
  machine,
  user,
  ...
}: {
  enable = true;
  package =
    if machine.isWork
    then pkgs.gitGoogle
    else pkgs.git;

  aliases = {
    ldiff = "difftool -t latex";
    ci = "commit";
    co = "checkout";
    lc = "log ORIG_HEAD.. --stat --no-merges";
    st = "status";
    ll = "log --graph --pretty=oneline --abbrev-commit --decorate=full";
    lla = "log --graph --pretty=oneline --abbrev-commit --decorate=full --all";
    cdiff = "difftool -y -x \"diff -cp\"";
    pu = "log master...next --cherry-pick --oneline --graph --decorate=full --no-merges --right-only";
    new = "!sh -c 'git log $1@{1}..$1@{0} \"$@\"'";
    whois = "!sh -c 'git log -i -1 --pretty=\"format:%an <%ae>\n\" --author=\"$1\"' -";
    whatis = "show -s --pretty='tformat:%h (%s, %ad)' --date=short";
  };

  delta.enable = true;
  delta.options = {
    syntax-theme = "OneHalfDark";
  };

  lfs.enable = true;

  userName = "${user.name}";
  userEmail = "${user.email}";

  extraConfig = {
    core = {
      deltaBaseCacheLimit = "128m";
    };

    colomn = {
      ui = "auto";
    };

    color = {
      diff = "auto";
      status = "auto";
      branch = "auto";
      ui = "auto";
    };

    "color.branch" = {
      current = "yellow reverse";
      local = "yellow";
      remote = "green";
    };

    "color.diff" = {
      meta = "yellow bold";
      frag = "magenta bold";
      old = "red bold";
      new = "green bold";
    };

    "color.status" = {
      added = "yellow";
      changed = "green";
      untracked = "cyan";
    };

    branch = {
      autosetupmerge = true;
      sort = "-committerdate";
    };

    "difftool.latex" = {
      cmd = "git-latexdiff \"$LOCAL\" \"$REMOTE\"";
    };

    "diff.lisp" = {
      xfuncname = "^(((;;;+ )|\\(|([ \t]+\\(((cl-|el-patch-)?def(un|var|macro|method|custom)|gb/))).*)$";
    };

    "diff.org" = {
      xfuncname = "^(\\*+ +.*)$";
    };

    difftool = {
      prompt = false;
    };

    rebase = {
      autosquash = true;
      updateRefs = true;
    };

    push = {
      default = "matching";
    };

    init = {
      defaultBranch = "main";
      templateDir = "${config.home.homeDirectory}/.git-template";
    };

    gitreview = {
      remote = "origin";
    };

    ghq = {
      root = "${config.home.homeDirectory}/src";
    };

    http = {
      cookiefile = "${config.home.homeDirectory}/.gitcookies";
    };

    include = {
      path = "${config.home.homeDirectory}/.gitconfig.private";
    };

    rerere = {
      enabled = true;
    };
  };

  attributes = [
    "*.lisp  diff=lisp"
    "*.el    diff=lisp"
    "*.org   diff=org"
  ];

  ignores = [
    # For emacs:
    "*~"
    "*.*~"
    "\\#*"
    ".\\#*"
    # For vim:
    "*.swp"
    ".*.sw[a-z]"
    "*.un~"
    ".netrwhist"
    # OS files
    ".DS_Store?"
    ".DS_Store"
    ".CFUserTextEncoding"
    ".Trash"
    ".Xauthority"
    "thumbs.db"
    "Thumbs.db"
    "Icon?"
    # Code
    ".ccls-cache/"
    ".sass-cache/"
    "__pycache__/"
    # Compiled things
    "*.class"
    "*.exe"
    "*.o"
    "*.pyc"
    "*.elc"
  ];
}
