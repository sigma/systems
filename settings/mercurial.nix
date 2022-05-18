{ config, pkgs, user, ... }:

{
  enable = true;
  package = pkgs.fig;

  aliases = {
    # Run blaze build on every modified target vs the parent commit.
    build = "!$HG targets | xargs blaze build \"$@\"";
    # Run blaze test on every test target in modified packages.
    test = "!$HG testtargets | xargs blaze test --test_size_filters=small,medium \"$@\"";
    # Runs tricorder on the current CL
    tricorder = "!tricorder analyze -fast $@";
    # prints the files in this revision that differ from the previous, as relative to the cwd
    whatsout = "status --rev .^ -man";
    desc = "log -T '{desc}' -r";
    pc = "pickcheckout";
    stat = "diff --stat";
    m = "ll -r 'smart and p4base::'";
    pub = "!$HG phase -d \"$@\"";
    # You always have to commit after merging anyway. Merge commit descriptions are pretty useless
    mc = "! $HG merge $1 && $HG commit -m \"merge\"";

    continue = "! $HG resolve --mark && $HG rebase --continue || $HG evolve --continue || $HG histedit --continue";

    ## Helper methods that are not as useful by themselves
    # What blaze targets (:all) are changed vs parent commit
    targets = "!$HG whatsout | sed -r 's#(.*)/.*$#\1:all#g' | sort -u";
    # Changed targets plus all the corresponding javatests targets.
    potentialtesttargets = "!$HG targets | sed -r 's|^java/(.*:all)|javatests/\1\\njava/\1|' | sort -u";
    # This step is mostly unnecessary for testing since we could just pass the
    # patterns directly to blaze test, but it allows passing --keep_going to the
    # blaze query step and skip targets that don't exist. Passing it to blaze
    # build directly would cause skipping other errors.
    testtargets = "!blaze query --keep_going \"tests($(hg potentialtesttargets | paste -s -d +))\"";
  };

  userName = "${user.name}";
  userEmail = "${user.email}";

  extraConfig = {
    alices = {
      "findings.extra_args" = "--proxy";
      "summarize.extra_args" = "--proxy";
    };

    color = {
      # shortest unique portion of the hash
      "changeset.shortest" = "";
      "changeset.remaining" = "bold black";
      "changeset.secret" = "red";
      # Colors for displaying CLs
      "google_compact.willupdatecl" = "red";
      "google_compact.patchedcl" = "magenta";
      "google_compact.exportedcl" = "green";
      "desc.here" = "bold underline";
    };

    diff = {
      git = true;
    };

    experimental = {
      graphshorten = true;
      "evolution.effect-flags" = false;
      # Shorter unique prefix http://g/fig-users/YnXRPpJEbgQ/gqf0gdGAFwAJ
      "revisions.prefixhexnode" = true;
    };

    extensions = {
      beautifygraph = "";
      "unsupported.alices" = "";
    };

    google_hgext = {
      "pickcheckout.enable_curses_ui" = true;
      "review-units.enable-store" = true;
      "ssopeer.keepalive" = true;
      "ssopeer.cachecookies" = true;
    };

    pager = {
      pager = "delta -s -n";
    };

    phases = {
      # New commits are in the secret phase, to be ignored by uploadchain/all
      new-commit = "secret";
    };

    templatealias = {
      google_compact_desc_text = "'{if(outsidenarrow, \"\", GOOG_trim_desc(desc))}'";
      google_compact_uniq_id = "'{GOOG_rev_and_node}'";
      # regex-aware version of ifcontains
      "ifmatches(regex, text, then, else)" = "ifcontains('_marker_string_', sub(regex, '_marker_string_', text), then, else)";
      # Get a tag from the description
      "tag(key)" = "splitlines(desc) % '{ifmatches('^{key}=', line, sub('^{key}=', '', line), '')}'";
      google_compact_willupdatecl = "label(\"google_compact.willupdatecl\", \"http://cl/{willupdatecl}\")";
      google_compact_exportedcl = "label(\"google_compact.exportedcl\", \"http://cl/{exportedcl}\")";
      google_compact_patchedcl = "label(\"google_compact.patchedcl\", \"http://cl/{patchedcl}\")";
      # Extracting the reason for a commit from its description
      bug_line = "sub('([0-9]+)', 'http://b/\\1', sub(', *', ' ', tag('BUG')))";
      tag_line = "splitlines(desc) % '{ifmatches('#(codehealth|biscuit)', line, line, '')}'";
      why_line = "separate(' ', bug_line, tag_line)";
      why = "if(piper_change_number, '', label('bold black', why_line))";
      # Unambiguous part of the node id. Inspired from GOOG_node
      yrh_rev_id = "label('changeset.{phase}', google_compact_unambiguous_shortest(node))";
      # Tags (mostly `tip` and `p4head` these days)
      yrh_tags = "separate(\" \", GOOG_tags, GOOG_bookmarks)";
      # CL information (for non-public CLs only)
      yrh_cl = "GOOG_cl_status";
      # Age of public CLs (p4base/p4head), description and reason for others
      yrh_desc = "if(piper_change_number, \"http://cl/{piper_change_number} {age(date)}\", GOOG_desc)";
      yrh_one_line = "separate(\" \", yrh_rev_id, yrh_tags, yrh_desc, yrh_cl, why)";
      yrh_two_lines = "separate(\"\\n\", separate(\" \" , yrh_rev_id, yrh_tags, yrh_desc), separate(\" \", why, yrh_cl))";
    };

    templates = {
      google_compact = "{yrh_two_lines}";
    };

    ui = {
      graphnodetemplate = "{label('changeset.{phase}', graphnode)}";
    };

    fix = {
      "rustfmt:command" = "rustfmt +nightly --config-path=google3/devtools/rust/rustfmt.toml";
      "rustfmt:pattern" = "set:\"**.rs\"";
      "rustfmt:priority" = -100;
    };
  };
}
