package Dist::Zilla::Plugin::GithubMeta;

BEGIN {
    $Dist::Zilla::Plugin::GithubMeta::VERSION = '0.02';
}

# ABSTRACT: Automatically include GitHub meta information in META.yml

use Moose;
with 'Dist::Zilla::Role::MetaProvider';

use MooseX::Types::URI qw[Uri];
use Cwd;
use IPC::Cmd qw[can_run];

has 'homepage' => (
  is => 'ro',
  isa => Uri,
  coerce => 1,
);

sub metadata {
  my $self = shift;
  return unless _under_git();
  return unless can_run('git');
  return unless my ($git_url) = `git remote show -n origin` =~ /URL: (.*)$/m;
  return unless $git_url =~ /github\.com/; # Not a Github repository
  my $homepage;
  if ( $self->homepage ) {
    $homepage = $self->homepage->as_string;
  }
  else {
    $homepage = $git_url;
    $homepage =~ s![\w\-]+\@([^:]+):!http://$1/!;
    $homepage =~ s!\.git$!/tree!;
  }
  $git_url =~ s![\w\-]+\@([^:]+):!git://$1/!;
  return { resources => { repository => { url => $git_url }, homepage => $homepage } };
}


sub _under_git {
  return 1 if -e '.git';
  my $cwd = getcwd;
  my $last = $cwd;
  my $found = 0;
  while (1) {
    chdir '..' or last;
    my $current = getcwd;
    last if $last eq $current;
    $last = $current;
    if ( -e '.git' ) {
       $found = 1;
       last;
    }
  }
  chdir $cwd;
  return $found;
}

__PACKAGE__->meta->make_immutable;
no Moose;

qq[1 is the loneliest number]

__END__

=head1 NAME

Dist::Zilla::Plugin::GithubMeta - Automatically include GitHub meta information in META.yml

=head1 SYNOPSIS

  # in dist.ini

  [GithubMeta]

  # to override the homepage

  [GithubMeta]
  homepage = http://some.sort.of.url/project/

=head1 DESCRIPTION

Dist::Zilla::Plugin::GithubMeta is a L<Dist::Zilla> plugin to include GitHub L<http://github.com> meta
information in C<META.yml>.

It automatically detects if the distribution directory is under C<git> version control and whether the 
C<origin> is a GitHub repository and will set the C<repository> and C<homepage> meta in C<META.yml> to the
appropriate URLs for GitHub.

=head2 ATTRIBUTES

=over

=item C<homepage>

You may override the C<homepage> setting by specifying this attribute. This should be a valid URL as 
understood by L<MooseX::Types::URI>.

=back

=head2 METHODS

=over

=item C<metadata>

Required by L<Dist::Zilla::Role::MetaProvider>

=back

=head1 AUTHOR

Chris C<BinGOs> Williams

Based on L<Module::Install::GithubMeta> which was based on 
L<Module::Install::Repository> by Tatsuhiko Miyagawa

=head1 LICENSE

Copyright E<copy> Chris Williams and Tatsuhiko Miyagawa

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

L<Dist::Zilla>

L<MooseX::Types::URI>

=cut
