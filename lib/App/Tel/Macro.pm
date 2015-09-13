package App::Tel::Macro;

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( handle_backspace handle_ctrl_z );

=head2 handle_backspace

Handle backspace for routers that use ^H

=cut

sub handle_backspace {
    ${$_[0]}->send("\b");
    return 1;
}

=head2 handle_ctrl_z

Handle ctrl_z for non-cisco boxes

=cut

sub handle_ctrl_z {
    ${$_[0]}->send("exit\r");
    return 1;
}

1;
