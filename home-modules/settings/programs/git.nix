{
  config,
  user,
  ...
}:
{
  enable = true;

  aliases = {
    ldiff = "difftool -t latex";
    ci = "commit";
    co = "checkout";
    lc = "log ORIG_HEAD.. --stat --no-merges";
    st = "status";
    lg = "log --graph --date=relative --pretty=tformat:'%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%an %ad)%Creset'";
    ll = "log --graph --pretty=oneline --abbrev-commit --decorate=full";
    lla = "log --graph --pretty=oneline --abbrev-commit --decorate=full --all";
    cdiff = "difftool -y -x \"diff -cp\"";
    oops = "commit --amend --no-edit";
    pu = "log master...next --cherry-pick --oneline --graph --decorate=full --no-merges --right-only";
    new = "!sh -c 'git log $1@{1}..$1@{0} \"$@\"'";
    whois = "!sh -c 'git log -i -1 --pretty=\"format:%an <%ae>\n\" --author=\"$1\"' -";
    whatis = "show -s --pretty='tformat:%h (%s, %ad)' --date=short";
  };

  delta.enable = true;
  delta.options = {
    navigate = true;
    hyperlinks = true;

    interactive = {
      "keep-plus-minus-markers" = false;
    };
  };

  lfs.enable = true;

  includes = [
    # defaults
    {
      contents = {
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

        diff = {
          mnemonicPrefix = true;
          renames = true;
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

        log = {
          abbrevCommit = true;
          follow = true;
        };

        merge = {
          conflictstyle = "zdiff3";
        };

        rebase = {
          autosquash = true;
          updateRefs = true;
        };

        pull = {
          rebase = "merges";
        };

        push = {
          default = "matching";
          followTags = true;
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

        rerere = {
          autoUpdate = true;
          enabled = true;
        };

        tag = {
          sort = "version:refname";
        };

        versionsort = {
          prereleaseSuffix = [
            "-pre"
            ".pre"
            "-beta"
            ".beta"
            "-rc"
            ".rc"
          ];
        };
      };

      contentSuffix = "defaults";
    }
    # id-related
    {
      contents =
        let
          profileEmail =
            name:
            let
              prof = builtins.head (builtins.filter (prof: prof.name == name) user.profiles);
            in
            builtins.head prof.emails;
        in
        {
          user.name = "${user.name}";
          # default to personal email. We'll override in work repos
          user.email = "${profileEmail "perso"}";

          github.user = "${user.githubHandle}";
          # force-use ssh for my own github repos
          url."ssh://git@github.com/${user.githubHandle}/".insteadOf =
            "https://github.com/${user.githubHandle}/";
        };

      contentSuffix = "id";
    }
    {
      contents = {
        "gpg" = {
          format = "ssh";
        };
        "gpg.ssh" = {
          defaultKeyCommand = "sh -c 'echo key::$(ssh-add -L)'";
        };
      };
      contentSuffix = "signing";
    }
    # auth tokens and the likes, stored outside of nix
    {
      path = "${config.home.homeDirectory}/.gitconfig.private";
    }
  ];

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
