package DBIx::Class::InflateColumn::ClassTypeEnum;

use warnings;
use strict;

use Function::Parameters;
use Carp ();

method register_column ($column, $info) {
  $self->next::method(@_);

  return unless $info->{extra} and my $class = $info->{extra}{enum_class};

  unless (eval { $class->isa('Class::Type::Enum') }) {
    Carp::croak "enum_class $class is not loaded or doesn't inherit from Class::Type::Enum";
  }

  # I'd love to DTRT based on the column type but I think they're practically
  # freeform in DBIC and just match the DB types, so that's a lot of
  # possibilities...

  $self->inflate_column(
    $column => {
      inflate => fun ($val = undef) {
        return unless defined $val;
        $class->inflate($val);
      },
      deflate => fun ($enum = undef) {
        return unless defined $enum;
        $enum->stringify;
      },
    }
  );
}

1;
