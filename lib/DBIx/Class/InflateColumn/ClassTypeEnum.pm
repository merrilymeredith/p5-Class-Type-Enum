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

  if ($info->{extra}{enum_is_ord}) {
    $self->inflate_column(
      $column => {
        inflate => fun ($ord = undef) {
          return unless defined $ord;
          $class->inflate($ord);
        },
        deflate => fun ($enum = undef) {
          return unless defined $enum;
          $enum->numify;
        },
      }
    );

  }
  else {
    $self->inflate_column(
      $column => {
        inflate => fun ($val = undef) {
          return unless defined $val;
          $class->inflate_value($val);
        },
        deflate => fun ($enum = undef) {
          return unless defined $enum;
          $enum->stringify;
        },
      }
    );
  }
}

1;
