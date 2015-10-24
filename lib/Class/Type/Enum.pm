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
  install_modifier $target, 'fresh', values_raw => sub { \%values };
  install_modifier $target, 'fresh', raw_values => sub { +{ reverse(%values) } };

  install_modifier $target, 'fresh', values => method {
    my $raw = $self->values_raw;
    [ sort { $raw->{$a} <=> $raw->{$b} } keys %values ];
  };

  for my $value (keys %values) {
    install_modifier $target, 'fresh', "is_$value" => method { $self->is($value) };
  }
}

method new ($class: $value) {
  $class->inflate($value);
}

method inflate ($class: $value) {
  bless \(
    $class->values_raw->{$value}
    // die "Value [$value] is not valid for enum $class"
  ), $class;
}

method get_test ($class:) {
  return fun ($value) {
    exists($class->values_raw->{$value})
      or die "Value [$value] is not valid for enum $class"
  }
}

method test ($class: $value) {
  $class->get_test->($value)
}


method is ($value) {
  $$self == ($self->values_raw->{$value} // die "Value [$value] is not valid for enum ". blessed($self))
}

method stringify {
  $self->raw_values->{$$self};
}

method numify {
  $$self
}


method any (@cases) {
  List::Util::any { $self->is($_) } @cases;
}

method none (@cases) {
  List::Util::none { $self->is($_) } @cases;
}

1;
