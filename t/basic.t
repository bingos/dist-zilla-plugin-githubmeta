use strict;
use warnings;
use Test::More 0.88;
use IPC::Cmd qw[can_run];

unless ( can_run('git') ) {
  ok('No git, no dice');
  done_testing;
  exit 0;
}

use lib 't/lib';

use Test::Deep qw(all ignore superhashof);
use Test::DZil;

test_plugin("simplest case, ssh url" => {
  plugin => { },
  git    => { origin => 'git@github.com:example/Example-Repo.git' },
});

test_plugin("use a non-default remote" => {
  plugin => { remote => 'github' },
  git    => {
    github => 'git@github.com:example/Example-Repo.git',
    origin => 'rjbs@git.manxome.org/zork/Gnusto.git',
  },
});

test_plugin("override the user" => {
  plugin => { user => 'example' },
  git    => { origin => 'git@github.com:rjbs/Example-Repo.git' },
});

test_plugin("override the repo" => {
  plugin => { repo => 'Example-Repo' },
  git    => { origin => 'git@github.com:example/example--repo.git' },
});

test_plugin("turn on issues" => {
  plugin => { issues => 1 },
  git    => { origin => 'git@github.com:example/Example-Repo.git' },
  resources => {
    bugtracker => { web => 'http://github.com/example/Example-Repo/issues' },
  },
});

done_testing;

#############

my %FMT;

BEGIN {
$FMT{CONFIG} = <<'END_GITCONFIG';
[core]
  repositoryformatversion = 0
  filemode = true
  bare = false
  logallrefupdates = true
%s
END_GITCONFIG

$FMT{REMOTE} = <<'END_REMOTE';
[remote "%s"]
  url = %s
END_REMOTE
}

sub git_config_for {
  my ($config) = @_;

  my $remote_config =
    join qq{\n}, map {; sprintf $FMT{REMOTE}, $_, $config->{$_} } keys %$config;

  return sprintf $FMT{CONFIG}, $remote_config;
}

sub test_plugin {
  my ($desc, $test) = @_;
  my $gitconfig = git_config_for($test);

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/GHM-Sample' },
    {
      add_files => {
        'source/dist.ini'    => simple_ini(
          'MetaJSON',
          [ GithubMeta => $test->{plugin} ],
        ),
        'source/.git/config' => git_config_for($test->{git}),
      },
      also_copy => {
        'corpus/git' => 'source/.git',
      },
    },
  );

  $tzil->build;

  is_json(
    $tzil->slurp_file('build/META.json'),
    all(
      $test->{meta} || ignore(),
      superhashof({
        resources => {
          homepage   => 'http://github.com/example/Example-Repo',
          repository => {
            type => 'git',
            url => 'http://github.com/example/Example-Repo',
            web => 'http://github.com/example/Example-Repo',
          },
          $test->{resources} ? %{ $test->{resources} } : (),
        },
      }),
    ),
    $desc,
  );
}
