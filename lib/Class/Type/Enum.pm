package Class::Type::Enum;

use strict;
use warnings;

use Function::Parameters ':strict';
use List::Util ();
use Scalar::Util qw(blessed);
use Class::Method::Modifiers qw(install_modifier);

use namespace::clean;

use overload (
  '""'     => 'stringify',
  '0+'     => 'numify',
  fallback => 1,
);

method import ($class: %params) {
  my $target = caller;

  my %values;

  if (ref $params{values} eq 'ARRAY') {
    my $i = $params{init} // 0;

    %values = map {
      $_ => ($params{bits} ? 2**($i++) : $i++)
    } @{$params{values}};
  }
  elsif (ref $params{values} eq 'HASH') {
    %values = %{$params{values}};
  }
  else {
    die "Enum values must be provided either as an array or hash ref.";
  }

  ## the bits that are installed into the target class, plus @ISA
  {
    no strict 'refs';
    push @{"${target}::ISA"}, $class;
  }
  install_modifier $target, 'fresh', values_ord => sub { \%values };
  install_modifier $target, 'fresh', ord_values => sub { +{ reverse(%values) } };

  install_modifier $target, 'fresh', values => method {
    my $ord = $self->values_ord;
    [ sort { $ord->{$a} <=> $ord->{$b} } keys %values ];
  };

  for my $value (keys %values) {
    install_modifier $target, 'fresh', "is_$value" => method { $self->is($value) };
  }
}

method new ($class: $value) {
  $class->inflate($value);
}

method inflate ($class: $value) {
  bless {
    ord => $class->values_ord->{$value}
        // die "Value [$value] is not valid for enum $class"
  }, $class;
}

method get_test ($class:) {
  return fun ($value) {
    exists($class->values_ord->{$value})
      or die "Value [$value] is not valid for enum $class"
  }
}

method test ($class: $value) {
  $class->get_test->($value)
}


method is ($value) {
  $self->{ord} == ($self->values_ord->{$value} // die "Value [$value] is not valid for enum ". blessed($self))
}

method stringify {
  $self->ord_values->{$self->{ord}};
}

method numify {
  $self->{ord}
}


method any (@cases) {
  List::Util::any { $self->is($_) } @cases;
}

method none (@cases) {
  List::Util::none { $self->is($_) } @cases;
}

1;
